import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/sales_order_model.dart';

class SalesOrderInvoicePdf {
  SalesOrderInvoicePdf._();

  static final _brand = PdfColor.fromHex('#6B65BD');
  static final _border = PdfColor.fromHex('#D1D5DB');
  static final _muted = PdfColor.fromHex('#6B7280');
  static final _row = PdfColor.fromHex('#F9FAFB');

  static Future<Uint8List> build(SalesOrderDetailModel order) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf'),
    );
    pw.MemoryImage? logo;
    try {
      final data =
          await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (_) => [
          _header(order, logo, bold),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('فاتورة طلبية مبيعات',
                style: pw.TextStyle(font: bold, fontSize: 16, color: _brand)),
          ),
          pw.SizedBox(height: 10),
          _meta(order, bold),
          if ((order.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _sectionTitle('ملاحظات', bold),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _row,
                border: pw.Border.all(color: _border),
              ),
              child: pw.Text(order.notes!.trim()),
            ),
          ],
          pw.SizedBox(height: 12),
          _sectionTitle('الأصناف', bold),
          _items(order, bold),
          pw.SizedBox(height: 12),
          _totals(order, bold),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> share(SalesOrderDetailModel order) async {
    final bytes = await build(order);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'sales_order_${order.serialNumber ?? order.id}.pdf',
    );
  }

  static Future<void> print(SalesOrderDetailModel order) async {
    final bytes = await build(order);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static pw.Widget _header(
    SalesOrderDetailModel order,
    pw.MemoryImage? logo,
    pw.Font bold,
  ) {
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: logo == null ? pw.SizedBox() : pw.Image(logo, height: 78),
          ),
          pw.Expanded(
            child: pw.Column(children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'sales-order:${order.id}',
                width: 62,
                height: 62,
              ),
              pw.SizedBox(height: 3),
              pw.Text(order.serialNumber ?? '#${order.id}',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(font: bold, fontSize: 9)),
            ]),
          ),
          pw.SizedBox(
            width: 120,
            child: pw.Text('دكتور بايك',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: bold, fontSize: 20, color: _brand)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _meta(SalesOrderDetailModel order, pw.Font bold) {
    final date = DateTime.tryParse(order.createdAt ?? '');
    final dateText = date == null ? '—' : DateFormat('yyyy/MM/dd').format(date);
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(children: [
        _metaRow('رقم الفاتورة', order.serialNumber ?? '#${order.id}',
            'التاريخ', dateText, bold),
        _metaRow('الزبون', order.customerName ?? '—', 'الهاتف',
            order.customerPhone ?? '—', bold),
        _metaRow('العنوان', order.customerAddress ?? order.cityName ?? '—',
            'حالة الطلبية', _statusLabel(order.status), bold),
        _metaRow('شركة التوصيل', order.deliveryCompanyName ?? '—', 'رقم التتبع',
            order.trackingNumber ?? '—', bold),
      ]),
    );
  }

  static pw.Widget _metaRow(
      String l1, String v1, String l2, String v2, pw.Font bold) {
    pw.Widget cell(String label, String value) => pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.RichText(
                text: pw.TextSpan(children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: bold)),
              pw.TextSpan(text: value),
            ])),
          ),
        );
    return pw.Row(
        children: [cell(l1, v1), pw.SizedBox(width: 18), cell(l2, v2)]);
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(title, style: pw.TextStyle(font: bold, color: _brand)),
      );

  static pw.Widget _items(SalesOrderDetailModel order, pw.Font bold) {
    final rows = order.items
        .asMap()
        .entries
        .map((entry) => [
              _money(entry.value.lineTotal),
              _money(entry.value.unitPrice),
              '${entry.value.quantity}',
              entry.value.productName ?? '—',
              '${entry.key + 1}',
            ])
        .toList();
    return pw.TableHelper.fromTextArray(
      headers: const ['الإجمالي', 'السعر', 'الكمية', 'الصنف', '#'],
      data: rows,
      headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _brand),
      oddRowDecoration: pw.BoxDecoration(color: _row),
      border: pw.TableBorder.all(color: _border),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    );
  }

  static pw.Widget _totals(SalesOrderDetailModel order, pw.Font bold) {
    pw.Widget line(String label, double value, {bool strong = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(children: [
            pw.Expanded(
                child: pw.Text(label,
                    style: strong ? pw.TextStyle(font: bold) : null)),
            pw.Text('${_money(value)} ₪',
                textDirection: pw.TextDirection.rtl,
                style: strong ? pw.TextStyle(font: bold, color: _brand) : null),
          ]),
        );
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(9),
      decoration:
          pw.BoxDecoration(color: _row, border: pw.Border.all(color: _border)),
      child: pw.Column(children: [
        line('المجموع', order.subtotal),
        line('التوصيل', order.customerDeliveryFee),
        line('الخصم', order.discount),
        line('الإجمالي', order.total, strong: true),
        line('دخل صندوق المحل', order.settlementCashTotal),
        line('دين على الزبون', order.customerDebtBalance),
        line('في ذمة شركة التوصيل', order.carrierReceivableBalance),
      ]),
    );
  }

  static String _money(double value) => NumberFormat('#,##0.00').format(value);

  static String _statusLabel(String status) {
    const labels = {
      'unconfirmed': 'غير مؤكدة',
      'confirmed': 'مؤكدة',
      'ready': 'جاهزة',
      'with_delivery': 'مع التوصيل',
      'review': 'قيد المراجعة',
      'delivered': 'مسلّمة',
      'partial_return': 'إرجاع جزئي',
      'returned': 'مرتجعة',
      'postponed': 'مؤجلة',
      'stuck': 'متعثرة',
      'canceled': 'ملغاة',
      'archived': 'مؤرشفة',
    };
    return labels[status] ?? status;
  }
}
