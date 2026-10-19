import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/sales_order_model.dart';
import '../../../../../core/helpers/show_net_image.dart';

class SalesOrderInvoicePdf {
  SalesOrderInvoicePdf._();

  static final _brand = PdfColor.fromHex('#6B65BD');
  static final _border = PdfColor.fromHex('#D1D5DB');
  static final _muted = PdfColor.fromHex('#6B7280');
  static final _row = PdfColor.fromHex('#F9FAFB');

  static Future<Uint8List> build(SalesOrderDetailModel order,
      {bool includeNotes = false, bool includeProductImages = false}) async {
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

    final rows = invoiceItems(order.items);
    final images = <int, pw.ImageProvider>{};
    if (includeProductImages) {
      for (final item in rows) {
        final raw = item.productImage ?? '';
        if (raw.isEmpty ||
            raw == 'no image' ||
            images.containsKey(item.productId)) {
          continue;
        }
        try {
          images[item.productId] =
              await networkImage(ShowNetImage.getPhoto(raw))
                  .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
    }
    final noteImages = <int, List<pw.ImageProvider>>{};
    if (includeNotes) {
      for (final note in order.noteLog) {
        final loaded = <pw.ImageProvider>[];
        for (final url in note.images) {
          try {
            loaded.add(
                await networkImage(url).timeout(const Duration(seconds: 8)));
          } catch (_) {}
        }
        noteImages[note.id] = loaded;
      }
    }
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
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              height: 1.3,
              color: _brand),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('فاتورة طلبية مبيعات',
                style: pw.TextStyle(font: bold, fontSize: 16, color: _brand)),
          ),
          pw.SizedBox(height: 10),
          _meta(order, bold),
          if (includeNotes && (order.notes ?? '').trim().isNotEmpty) ...[
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
          _items(rows, bold, images, includeProductImages),
          pw.SizedBox(height: 12),
          _totals(order, bold),
          if (includeNotes) ...[
            for (final note in order.noteLog) ...[
              pw.SizedBox(height: 10),
              _sectionTitle(
                  '${note.scope == 'internal' ? 'ملاحظة داخلية' : 'تعليق'} - ${note.userName}',
                  bold),
              if (note.note.isNotEmpty) pw.Text(note.note),
              pw.Wrap(spacing: 6, runSpacing: 6, children: [
                for (final image in noteImages[note.id] ?? <pw.ImageProvider>[])
                  pw.Container(
                      width: 145,
                      height: 110,
                      child: pw.Image(image, fit: pw.BoxFit.contain)),
              ]),
            ],
          ],
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

  /// The server statement hides operational rows and merges equal item/variant prices.
  static List<SalesOrderItemModel> invoiceItems(
      List<SalesOrderItemModel> items) {
    final grouped = <String, SalesOrderItemModel>{};
    for (final item in items.where((item) => !item.isHidden)) {
      final key = [
        item.productId,
        item.sizeId,
        item.sizeColorId,
        item.productName,
        item.unitPrice
      ].join('|');
      final old = grouped[key];
      grouped[key] = old == null
          ? item
          : SalesOrderItemModel(
              id: old.id,
              productId: old.productId,
              productName: old.productName,
              productImage: old.productImage ?? item.productImage,
              sizeId: old.sizeId,
              sizeColorId: old.sizeColorId,
              sizeLabel: old.sizeLabel,
              colorLabel: old.colorLabel,
              quantity: old.quantity + item.quantity,
              deliveredQty: old.deliveredQty + item.deliveredQty,
              dispatchedQty: old.dispatchedQty + item.dispatchedQty,
              returnedQty: old.returnedQty + item.returnedQty,
              unitPrice: old.unitPrice,
              lineTotal: old.lineTotal + item.lineTotal,
            );
    }
    return grouped.values.toList();
  }

  static pw.Widget _items(List<SalesOrderItemModel> items, pw.Font bold,
      Map<int, pw.ImageProvider> images, bool includeImages) {
    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      final variant = [item.sizeLabel, item.colorLabel]
          .whereType<String>()
          .where((label) => label.trim().isNotEmpty)
          .join(' / ');
      return <dynamic>[
        _money(item.lineTotal),
        _money(item.unitPrice),
        '${item.quantity}',
        if (includeImages) images[item.productId],
        [item.productName ?? '—', if (variant.isNotEmpty) variant].join('\n'),
        '${entry.key + 1}',
      ];
    }).toList();
    final headers = [
      'الإجمالي',
      'السعر',
      'الكمية',
      if (includeImages) 'الصورة',
      'الصنف',
      '#'
    ];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: [
        for (final row in rows)
          [
            for (final cell in row)
              if (cell is pw.ImageProvider)
                pw.SizedBox(
                    width: 40,
                    height: 40,
                    child: pw.Image(cell, fit: pw.BoxFit.contain))
              else
                pw.Text(cell?.toString() ?? '—',
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl),
          ]
      ],
      tableDirection: pw.TextDirection.ltr,
      headerDirection: pw.TextDirection.rtl,
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _brand),
      oddRowDecoration: pw.BoxDecoration(color: _row),
      border: pw.TableBorder.all(color: _border),
      columnWidths: {
        0: const pw.FixedColumnWidth(62),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(36),
        if (includeImages) 3: const pw.FixedColumnWidth(48),
        headers.length - 1: const pw.FixedColumnWidth(22)
      },
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
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                pw.Text(_money(value),
                    style: strong
                        ? pw.TextStyle(font: bold, color: _brand)
                        : null),
                pw.SizedBox(width: 4),
                pw.Text('شيكل',
                    textDirection: pw.TextDirection.rtl,
                    style: strong
                        ? pw.TextStyle(font: bold, color: _brand)
                        : null),
              ]),
            ),
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
        if (order.paymentAmount > 0)
          line(
              order.status == 'unconfirmed'
                  ? 'الدفعة المحددة'
                  : 'الدفعة المسجلة',
              order.paymentAmount),
        if (order.customerDebtBalance > 0)
          line('المتبقي على الزبون', order.customerDebtBalance),
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
      'partial_delivered': 'تسليم جزئي',
      'alternative_return': 'مرتجع استبدال',
      'returned': 'مرتجعة',
      'postponed': 'مؤجلة',
      'stuck': 'متعثرة',
      'canceled': 'ملغاة',
      'archived': 'مؤرشفة',
    };
    return labels[status] ?? status;
  }
}
