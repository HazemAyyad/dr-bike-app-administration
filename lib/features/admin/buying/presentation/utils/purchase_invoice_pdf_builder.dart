import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../data/models/bills_models/bills_details_model.dart';
import 'purchase_status_labels.dart';

/// Builds purchase invoices with the same local pdf/printing mechanism and
/// visual language used by the sales invoice.
class PurchaseInvoicePdfBuilder {
  PurchaseInvoicePdfBuilder._();

  static final PdfColor _brandColor = PdfColor.fromHex('#6B65BD');
  static final PdfColor _mutedColor = PdfColor.fromHex('#6B7280');

  static Future<pw.Font> _regular() async {
    final data = await rootBundle.load(
      'assets/fonts/Almarai/Almarai-Regular.ttf',
    );
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _bold() async {
    final data = await rootBundle.load(
      'assets/fonts/Almarai/Almarai-Bold.ttf',
    );
    return pw.Font.ttf(data);
  }

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data =
          await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _money(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return NumberFormat('#,##0.00').format(parsed ?? 0);
  }

  static pw.Widget _amount(
    dynamic value, {
    required pw.Font font,
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              _money(value),
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(font: font, fontSize: 9),
            ),
            pw.SizedBox(width: 3),
            pw.Text(
              'شيكل',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: font, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  static Future<pw.ImageProvider?> _productImage(String imageUrl) async {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty || trimmed == 'no image') return null;
    final resolved = ShowNetImage.getPhoto(trimmed);
    if (resolved.isEmpty) return null;
    try {
      return await networkImage(resolved);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> build(
    BillDetailsModel invoice, {
    bool includeProductImages = false,
  }) async {
    final regular = await _regular();
    final bold = await _bold();
    final logo = await _logo();
    final images = <int, pw.ImageProvider?>{};
    if (includeProductImages) {
      await Future.wait(
        invoice.products.map((item) async {
          images[item.billItemId] = await _productImage(item.productImage);
        }),
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        build: (_) => [
          _maintenanceStyleHeader(
            invoice: invoice,
            logo: logo,
            bold: bold,
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8, bottom: 10),
            height: 1.3,
            color: _brandColor,
          ),
          pw.Center(
            child: pw.Text(
              'فاتورة مشتريات',
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 8),
          _invoiceHeader(
            bold: bold,
            regular: regular,
            rows: [
              ['رقم الفاتورة', '${invoice.billId}'],
              ['التاريخ', invoice.createdAt],
              ['المورد', invoice.sellerName],
              ['حالة الدفع', purchasePaymentStatusLabel(invoice.paymentStatus)],
              [
                'حالة المشتريات',
                purchaseWorkflowLabel(invoice.workflowStatus),
              ],
            ],
          ),
          pw.SizedBox(height: 12),
          _itemsTable(
            invoice.products,
            images: images,
            regular: regular,
            bold: bold,
            includeProductImages: includeProductImages,
          ),
          if (invoice.payments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('الدفعات', style: pw.TextStyle(font: bold, fontSize: 12)),
            pw.SizedBox(height: 5),
            _paymentsTable(invoice.payments, regular: regular, bold: bold),
          ],
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: _totalsTable(
                regular: regular,
                bold: bold,
                rows: [
                  ['المجموع الفرعي', invoice.totalBill],
                  ['إجمالي الفاتورة', invoice.finalTotal],
                  ['المبلغ المدفوع', invoice.paidAmount],
                  ['المبلغ المتبقي', invoice.remainingAmount],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _maintenanceStyleHeader({
    required BillDetailsModel invoice,
    required pw.MemoryImage? logo,
    required pw.Font bold,
  }) {
    final qrPayload = [
      'purchase-invoice:${invoice.billId}',
      'supplier:${invoice.sellerName}',
      'date:${invoice.createdAt}',
      'total:${invoice.finalTotal}',
      'paid:${invoice.paidAmount}',
    ].join('|');

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 130,
            height: 88,
            child: logo == null
                ? pw.SizedBox()
                : pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, height: 88),
                  ),
          ),
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload,
                  width: 64,
                  height: 64,
                  drawText: false,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '${invoice.billId}',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontSize: 8, color: _mutedColor),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'دكتور بايك - فاتورة مشتريات',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 21,
                  color: _brandColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(
    List<BillProductModel> products, {
    required Map<int, pw.ImageProvider?> images,
    required pw.Font regular,
    required pw.Font bold,
    required bool includeProductImages,
  }) {
    final headers = [
      '#',
      if (includeProductImages) 'الصورة',
      'كود المنتج',
      'اسم المنتج',
      'الكمية',
      'السعر',
      'الإجمالي',
    ].reversed.toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .7),
      columnWidths: includeProductImages
          ? const {
              0: pw.FixedColumnWidth(64),
              1: pw.FixedColumnWidth(56),
              2: pw.FixedColumnWidth(42),
              3: pw.FlexColumnWidth(4),
              4: pw.FixedColumnWidth(58),
              5: pw.FixedColumnWidth(44),
              6: pw.FixedColumnWidth(24),
            }
          : const {
              0: pw.FixedColumnWidth(64),
              1: pw.FixedColumnWidth(56),
              2: pw.FixedColumnWidth(42),
              3: pw.FlexColumnWidth(4),
              4: pw.FixedColumnWidth(58),
              5: pw.FixedColumnWidth(24),
            },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.deepPurple600),
          children: headers
              .map((text) => _cell(text,
                  font: bold,
                  color: PdfColors.white,
                  alignment: pw.Alignment.centerRight))
              .toList(),
        ),
        ...List.generate(products.length, (index) {
          final item = products[index];
          final cells = <pw.Widget>[
            _amount(item.subTotal, font: regular),
            _amount(item.price, font: regular),
            _cell(item.quantity, font: regular),
            _productCell(item, regular: regular, bold: bold),
            _cell(item.productCode.isEmpty ? '-' : item.productCode,
                font: regular),
            if (includeProductImages)
              _imageCell(images[item.billItemId], regular: regular),
            _cell('${index + 1}', font: regular),
          ];
          return pw.TableRow(children: cells);
        }),
      ],
    );
  }

  static pw.Widget _productCell(
    BillProductModel item, {
    required pw.Font regular,
    required pw.Font bold,
  }) =>
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(item.productName,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: bold, fontSize: 9)),
            if (item.variantLabel.isNotEmpty)
              pw.Text(item.variantLabel,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: regular, fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      );

  static pw.Widget _imageCell(
    pw.ImageProvider? image, {
    required pw.Font regular,
  }) =>
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(3),
        height: 42,
        child: image == null
            ? pw.Text('-', style: pw.TextStyle(font: regular))
            : pw.Image(image, fit: pw.BoxFit.contain),
      );

  static pw.Widget _totalsTable({
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: .7),
        children: rows.map((row) {
          final isTotal = row.first == 'إجمالي الفاتورة';
          return pw.TableRow(
            decoration: isTotal
                ? const pw.BoxDecoration(color: PdfColors.grey200)
                : null,
            children: [
              _amount(row[1],
                  font: isTotal ? bold : regular,
                  alignment: pw.Alignment.centerLeft),
              _cell(row[0], font: isTotal ? bold : regular),
            ],
          );
        }).toList(),
      );

  static pw.Widget _paymentsTable(
    List<PurchasePaymentUiModel> payments, {
    required pw.Font regular,
    required pw.Font bold,
  }) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: .7),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.deepPurple600),
            children: ['ملاحظة', 'الصندوق', 'الطريقة', 'التاريخ', 'المبلغ']
                .map((value) => _cell(value,
                    font: bold,
                    color: PdfColors.white,
                    alignment: pw.Alignment.centerRight))
                .toList(),
          ),
          ...payments.map(
            (payment) => pw.TableRow(children: [
              _cell(payment.note.isEmpty ? '-' : payment.note, font: regular),
              _cell(payment.boxName.isEmpty ? '-' : payment.boxName,
                  font: regular),
              _cell(purchasePaymentTypeLabel(payment.paymentType),
                  font: regular),
              _cell(payment.paidAt, font: regular),
              _amount(payment.amount, font: regular),
            ]),
          ),
        ],
      );

  static pw.Widget _invoiceHeader({
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: .8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Wrap(
          spacing: 12,
          runSpacing: 6,
          children: rows
              .map((row) => pw.SizedBox(
                    width: 235,
                    child: pw.Row(children: [
                      pw.Text('${row[0]}: ',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(font: bold, fontSize: 9.5)),
                      pw.Expanded(
                        child: pw.Text(row[1].trim().isEmpty ? '-' : row[1],
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(font: regular, fontSize: 9.5)),
                      ),
                    ]),
                  ))
              .toList(),
        ),
      );

  static pw.Widget _cell(
    String text, {
    required pw.Font font,
    PdfColor? color,
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) =>
      pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(text,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: font, color: color, fontSize: 9)),
      );
}
