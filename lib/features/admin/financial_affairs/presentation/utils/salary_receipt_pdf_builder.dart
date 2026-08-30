import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SalaryReceiptPdfBuilder {
  SalaryReceiptPdfBuilder._();

  static final PdfColor _brand = PdfColor.fromHex('#6C5CE7');
  static final PdfColor _navy = PdfColor.fromHex('#111827');
  static final PdfColor _green = PdfColor.fromHex('#34C759');
  static final PdfColor _muted = PdfColor.fromHex('#6B7280');
  static final PdfColor _border = PdfColor.fromHex('#D1D5DB');
  static final PdfColor _soft = PdfColor.fromHex('#F5F3FF');

  static Future<pw.Font> _font(String weight) async => pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-$weight.ttf'),
      );

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data =
          await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> receipt,
    Uint8List? employeeSignature,
  }) async {
    final regular = await _font('Regular');
    final bold = await _font('Bold');
    final logo = await _logo();
    final employee = _map(receipt['employee']);
    final user = _map(employee['user']);
    final period = _map(receipt['salary_period']);
    final batch = _map(receipt['batch']);
    final creator = _map(batch['creator']);
    final snapshot = _map(period['calculation_snapshot']);
    final attendance = _map(snapshot['attendance']);
    final status = '${receipt['receipt_status'] ?? 'pending'}';
    final paidAmount = double.tryParse('${receipt['amount_paid']}') ?? 0;
    final monthRaw = '${period['salary_month'] ?? ''}';
    final month = monthRaw.length >= 7 ? monthRaw.substring(0, 7) : monthRaw;

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle:
              pw.TextStyle(font: regular, fontSize: 11, color: _navy),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _border))),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Doctor Bike • نظام الرواتب',
                    style: pw.TextStyle(color: _muted, fontSize: 8)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: pw.TextStyle(color: _muted, fontSize: 8)),
              ]),
        ),
        build: (_) => [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            if (logo != null)
              pw.Container(
                  width: 82,
                  height: 52,
                  child: pw.Image(logo, fit: pw.BoxFit.contain))
            else
              pw.Text('دكتور بايك',
                  style: pw.TextStyle(font: bold, fontSize: 18, color: _brand)),
            pw.Spacer(),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('سند صرف واستلام راتب',
                  style: pw.TextStyle(font: bold, fontSize: 18, color: _navy)),
              pw.SizedBox(height: 3),
              pw.Text('رقم السند: PAYROLL-${receipt['id']}',
                  style: pw.TextStyle(font: bold, color: _brand)),
            ]),
          ]),
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              height: 1.4,
              color: _brand),
          _metaBox(bold, [
            ['اسم الموظف', '${user['name'] ?? '-'}'],
            ['شهر الراتب', month],
            ['تاريخ الصرف', '${batch['payment_date'] ?? '-'}'],
            ['الصادر بواسطة', '${creator['name'] ?? 'إدارة دكتور بايك'}'],
          ]),
          pw.SizedBox(height: 12),
          _section('ملخص الاستحقاق والدفع', bold),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: _border, width: .7),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _brand),
                children: [
                  'المتبقي بعد الدفعة',
                  'المبلغ المدفوع',
                  'السلف المسواة',
                  'الإضافي والمكافآت',
                  'إجمالي الاستحقاق'
                ]
                    .map((text) =>
                        _cell(text, bold, color: PdfColors.white, header: true))
                    .toList(),
              ),
              pw.TableRow(
                  children: [
                _money(receipt['remaining_after']),
                _money(receipt['amount_paid']),
                _money(period['advances_applied']),
                _money(period['bonuses']),
                _money(period['gross_entitlement']),
              ].map((text) => _cell('$text شيكل', bold)).toList()),
            ],
          ),
          pw.SizedBox(height: 12),
          _section('تفاصيل احتساب الدوام', bold),
          pw.SizedBox(height: 6),
          _metaBox(bold, [
            ['ساعات الدوام المطلوبة', '${attendance['required_hours'] ?? '-'}'],
            ['ساعات الدوام الفعلية', '${attendance['worked_hours'] ?? '-'}'],
            ['الساعات الإضافية', '${attendance['overtime_hours'] ?? '-'}'],
            [
              'راتب الساعات الإضافية',
              '${_money(attendance['overtime_salary'])} شيكل'
            ],
          ]),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: _soft, borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Text(
              paidAmount <= 0
                  ? 'أقر أنا ${user['name'] ?? 'الموظف'} بأنني راجعت ووافقت على تسوية راتب شهر $month بالكامل مقابل السلف المستحقة، حسب التفاصيل المبينة في هذا السند.'
                  : 'أقر أنا ${user['name'] ?? 'الموظف'} بأنني استلمت مبلغ ${_money(receipt['amount_paid'])} شيكل عن راتب شهر $month، وذلك حسب التفاصيل المبينة في هذا السند.',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: bold, lineSpacing: 3),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: _signatureBox(
                title: 'توقيع وختم دكتور بايك',
                subtitle: '${creator['name'] ?? 'الإدارة'}',
                bold: bold,
                company: true,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _signatureBox(
                title: 'توقيع الموظف',
                subtitle: status == 'received'
                    ? 'تم التوقيع والاستلام'
                    : status == 'disputed'
                        ? 'يوجد اعتراض على الدفعة'
                        : 'بانتظار التوقيع',
                bold: bold,
                image: employeeSignature == null
                    ? null
                    : pw.MemoryImage(employeeSignature),
              ),
            ),
          ]),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Row(children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data:
                    '${receipt['verification_url'] ?? receipt['verification_code'] ?? receipt['verification_text'] ?? '-'}',
                width: 54,
                height: 54,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('رمز التحقق الرقمي',
                          style: pw.TextStyle(font: bold, fontSize: 9)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          '${receipt['verification_text'] ?? receipt['verification_code'] ?? '-'}',
                          textDirection: pw.TextDirection.ltr,
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          'أي تعديل على قيمة الدفعة أو التوقيع يغيّر بصمة السند الرقمية.',
                          style: pw.TextStyle(color: _muted, fontSize: 8)),
                    ]),
              ),
            ]),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _metaBox(pw.Font bold, List<List<String>> rows) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border),
            borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Wrap(
          spacing: 18,
          runSpacing: 8,
          children: rows
              .map((row) => pw.Container(
                    width: 225,
                    child: pw.Row(children: [
                      pw.Text('${row[0]}: ',
                          style: pw.TextStyle(font: bold, color: _muted)),
                      pw.Expanded(
                          child:
                              pw.Text(row[1], style: pw.TextStyle(font: bold))),
                    ]),
                  ))
              .toList(),
        ),
      );

  static pw.Widget _section(String text, pw.Font bold) => pw.Row(children: [
        pw.Container(width: 4, height: 17, color: _brand),
        pw.SizedBox(width: 6),
        pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13)),
      ]);

  static pw.Widget _cell(String text, pw.Font bold,
          {PdfColor? color, bool header = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                font: header ? bold : null, color: color, fontSize: 9)),
      );

  static pw.Widget _signatureBox({
    required String title,
    required String subtitle,
    required pw.Font bold,
    pw.MemoryImage? image,
    bool company = false,
  }) =>
      pw.Container(
        height: 112,
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: company ? _brand : _border, width: company ? 1.2 : .8),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text(title,
              style: pw.TextStyle(font: bold, color: company ? _brand : _navy)),
          pw.SizedBox(height: 6),
          if (image != null)
            pw.Expanded(child: pw.Image(image, fit: pw.BoxFit.contain))
          else if (company)
            pw.Expanded(
                child: pw.Center(
                    child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _green, width: 2),
                  borderRadius: pw.BorderRadius.circular(20)),
              child: pw.Text('DOCTOR BIKE\nمعتمد',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: bold, color: _green)),
            )))
          else
            pw.Spacer(),
          pw.Text(subtitle,
              style: pw.TextStyle(font: bold, color: _muted, fontSize: 8)),
        ]),
      );

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _money(dynamic value) =>
      NumberFormat('#,##0.00').format(double.tryParse('$value') ?? 0);
}
