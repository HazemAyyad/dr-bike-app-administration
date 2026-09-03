import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../data/sales_return_models.dart';

class SalesReturnInvoicePdf {
  SalesReturnInvoicePdf._();

  static String filename(SalesReturnRecord record) {
    final safe = record.serialNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'sales_return_${safe.isEmpty ? record.id : safe}.pdf';
  }

  static Future<Uint8List> build(SalesReturnRecord record) async {
    final regularData =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    final boldData =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/dark_Logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final itemRows = <List<dynamic>>[];
    for (var index = 0; index < record.items.length; index++) {
      final item = record.items[index];
      final source = item.saleInvoice;
      final variant = [item.sizeLabel, item.colorLabel]
          .where((value) => value.trim().isNotEmpty)
          .join(' / ');
      pw.ImageProvider? productImage;
      final rawImage = item.productImages.isNotEmpty
          ? item.productImages.first
          : item.productImage;
      if (rawImage.trim().isNotEmpty && rawImage != 'no image') {
        try {
          productImage = await networkImage(ShowNetImage.getPhoto(rawImage));
        } catch (_) {}
      }
      final purchaseDetails = item.purchaseSources.isEmpty
          ? 'غير موثقة تاريخيًا'
          : item.purchaseSources
              .map((purchase) =>
                  '#${purchase.billId}\nكمية ${_quantity(purchase.invoiceQuantity)} / مستلم ${_quantity(purchase.receivedQuantity)}\nتكلفة ${_money(purchase.unitCost)} ${purchase.currency}')
              .join('\n');
      itemRows.add([
        '${index + 1}',
        productImage == null
            ? '-'
            : pw.Image(productImage,
                width: 34, height: 34, fit: pw.BoxFit.cover),
        '${item.productName}${variant.isEmpty ? '' : '\n$variant'}\n${item.quantity} × ${_money(item.unitPrice)} ₪',
        source == null ? 'غير موثقة' : '${source.typeLabel}\n${source.serial}',
        purchaseDetails,
        '${source?.soldQuantity ?? '-'}',
        '${item.quantity}',
        '${_money(item.lineTotal)} ₪',
      ]);
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        build: (_) => [
          pw.Row(children: [
            pw.Expanded(
              child: pw.Text(
                'دكتور بايك - فاتورة مرتجع مبيعات',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 20,
                  color: PdfColors.deepPurple600,
                ),
              ),
            ),
            if (logo != null) pw.Image(logo, height: 82),
          ]),
          pw.Container(
            height: 1.3,
            margin: const pw.EdgeInsets.symmetric(vertical: 9),
            color: PdfColors.deepPurple600,
          ),
          _infoTable(record),
          pw.SizedBox(height: 12),
          pw.Text('المنتجات المرتجعة وتفاصيل فاتورة البيع',
              style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.deepPurple600),
            cellStyle: pw.TextStyle(font: regular, fontSize: 8.5),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            columnWidths: const {
              0: pw.FixedColumnWidth(22),
              1: pw.FixedColumnWidth(42),
              2: pw.FlexColumnWidth(2.1),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(1.7),
              5: pw.FlexColumnWidth(.8),
              6: pw.FlexColumnWidth(.8),
              7: pw.FlexColumnWidth(1.1),
            },
            headers: const [
              '#',
              'الصورة',
              'المنتج',
              'فاتورة البيع',
              'مصدر الشراء FIFO',
              'كمية البيع',
              'كمية المرتجع',
              'الإجمالي',
            ],
            data: itemRows,
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 245,
              child: pw.TableHelper.fromTextArray(
                cellStyle: pw.TextStyle(font: regular, fontSize: 9),
                data: [
                  ['إجمالي المرتجع', '${_money(record.totalAmount)} ₪'],
                  ['المعاد نقدًا', '${_money(record.cashRefundAmount)} ₪'],
                  ['المسجل رصيدًا', '${_money(record.creditAmount)} ₪'],
                ],
              ),
            ),
          ),
          if (record.note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('ملاحظة: ${record.note}',
                style: pw.TextStyle(font: regular, fontSize: 9)),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'هذه الفاتورة مرتبطة محاسبيًا بفواتير البيع المبينة أعلاه، وتوثق قيمة وكميات المنتجات المرتجعة وطريقة رد المبلغ.',
            style: pw.TextStyle(
              font: regular,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _infoTable(SalesReturnRecord record) {
    final sourceNumbers = record.sourceInvoices.isEmpty
        ? 'غير موثقة تاريخيًا'
        : record.sourceInvoices.map((invoice) => invoice.serial).join('، ');
    return pw.TableHelper.fromTextArray(
      cellStyle: const pw.TextStyle(fontSize: 9),
      data: [
        ['رقم فاتورة المرتجع', record.serialNumber],
        ['التاريخ', _date(record.completedAt)],
        ['حالة المرتجع', record.isCancelled ? 'ملغى' : 'فعال'],
        ['الطرف', record.partnerName],
        ['فاتورة/فواتير البيع الأصلية', sourceNumbers],
        if (record.isCancelled) ['سبب الإلغاء', record.cancellationReason],
      ],
      cellAlignments: const {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.2),
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static String _money(num value) => NumberFormat('#,##0.00').format(value);

  static String _quantity(num value) => NumberFormat('#,##0.##').format(value);

  static String _date(String raw) {
    final date = DateTime.tryParse(raw);
    return date == null ? raw : DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}
