import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/binding/sales_binding.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../data/models/maintenance_invoice_model.dart';

void showMaintenanceInvoiceSheet(
  BuildContext context,
  MaintenanceInvoiceModel invoice,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MaintenanceInvoiceSheet(invoice: invoice),
  );
}

class _MaintenanceInvoiceSheet extends StatelessWidget {
  const _MaintenanceInvoiceSheet({required this.invoice});

  final MaintenanceInvoiceModel invoice;

  String _money(double value) => NumberFormat('#,##0.##').format(value);

  Future<void> _openLinkedSalesInvoice() async {
    final saleId = invoice.instantSaleId;
    if (saleId == null) return;

    if (!Get.isRegistered<SalesController>() &&
        !Get.isPrepared<SalesController>()) {
      SalesBinding().dependencies();
    }
    await Get.find<SalesController>().openInstantSaleBillDetails(
      saleId.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final isPaid = invoice.paymentStatus == 'paid';
    final paymentStateColor = isPaid
        ? Colors.green
        : invoice.hasDebt
            ? Colors.orange
            : Colors.red;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.86.sh),
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'maintenanceInvoice'.tr,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          invoice.invoiceNumber,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  QrImageView(
                    data: invoice.qrPayload,
                    size: 52.w,
                    padding: EdgeInsets.all(3.w),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(width: 4.w),
                  IconButton(
                    tooltip: 'pdf'.tr,
                    onPressed: () async {
                      final bytes = await MaintenanceInvoicePdfBuilder.build(
                        invoice,
                      );
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename:
                            'maintenance_invoice_${invoice.maintenanceId}.pdf',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                  IconButton(
                    tooltip: 'print'.tr,
                    onPressed: () async {
                      final bytes = await MaintenanceInvoicePdfBuilder.build(
                        invoice,
                      );
                      await Printing.layoutPdf(
                        name:
                            'maintenance_invoice_${invoice.maintenanceId}.pdf',
                        onLayout: (_) async => bytes,
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                  ),
                  if (invoice.instantSaleId != null)
                    IconButton(
                      tooltip: 'instantSaleInvoice'.tr,
                      onPressed: _openLinkedSalesInvoice,
                      icon: const Icon(Icons.point_of_sale_outlined),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            Flexible(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _meta('billNumber'.tr, invoice.invoiceNumber),
                  _meta('date'.tr, invoice.invoiceDateDisplay),
                  _meta('maintenanceNumber'.tr, '#${invoice.maintenanceId}'),
                  _meta('status'.tr, invoice.maintenanceStatusLabel),
                  _meta('invoiceStatus'.tr, invoice.paymentStatusLabel),
                  _meta('buyerTypeSale'.tr, invoice.customerTypeLabel),
                  _meta('buyerName'.tr, invoice.customerName),
                  if (invoice.customerPhone?.trim().isNotEmpty == true)
                    _meta('phoneNumberTitle'.tr, invoice.customerPhone!),
                  if (invoice.customerAddress?.trim().isNotEmpty == true)
                    _meta('العنوان', invoice.customerAddress!),
                  if (invoice.receiptDateTimeDisplay.trim().isNotEmpty)
                    _meta('موعد الاستلام', invoice.receiptDateTimeDisplay),
                  SizedBox(height: 12.h),
                  if (invoice.services.isNotEmpty) ...[
                    _sectionTitle('الخدمات المنفذة'),
                    SizedBox(height: 8.h),
                    _servicesTable(),
                    SizedBox(height: 14.h),
                  ],
                  if (invoice.items.isNotEmpty) ...[
                    _sectionTitle('المنتجات وقطع الغيار'),
                    SizedBox(height: 8.h),
                    _itemsTable(),
                  ],
                  if (invoice.notes.trim().isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _sectionTitle('ملاحظات الصيانة'),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(invoice.notes),
                    ),
                  ],
                  Divider(height: 24.h),
                  _total('maintenancePartsTotal'.tr, invoice.partsTotal),
                  _total('maintenanceLaborCost'.tr, invoice.laborCost),
                  _total('discount'.tr, invoice.discount),
                  _total('totalBill'.tr, invoice.invoiceTotal, bold: true),
                  _total('paidAmount'.tr, invoice.paidAmount),
                  _total('remainingAmount'.tr, invoice.remainingAmount),
                  Container(
                    margin: EdgeInsets.only(top: 8.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: paymentStateColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_outline
                              : Icons.account_balance_wallet_outlined,
                          color: paymentStateColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isPaid
                                ? 'الفاتورة مدفوعة بالكامل'
                                : invoice.hasDebt
                                    ? 'يوجد دين متبقٍ: ${_money(invoice.debtAmount)} ${invoice.currency}'
                                    : 'لم يتم دفع كامل الفاتورة بعد، المتبقي: ${_money(invoice.remainingAmount)} ${invoice.currency}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: paymentStateColor.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (invoice.payments.isNotEmpty) ...[
                    Divider(height: 20.h),
                    Text(
                      'تفاصيل الدفع',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ...invoice.payments.map(
                      (payment) => _meta(
                        _paymentLabel(payment.method),
                        [
                          _money(payment.amount),
                          if (payment.createdAt?.trim().isNotEmpty == true)
                            payment.createdAt!.trim(),
                          if (payment.note?.trim().isNotEmpty == true)
                            payment.note!.trim(),
                        ].join(' - '),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'visa':
        return 'فيزا';
      case 'bank_transfer':
        return 'حوالة';
      default:
        return 'كاش';
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _servicesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.35),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(0.9),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _tableCell('#', bold: true, center: true),
            _tableCell('الخدمة', bold: true),
            _tableCell('السعر', bold: true, center: true),
          ],
        ),
        ...invoice.services.asMap().entries.map(
              (entry) => TableRow(
                children: [
                  _tableCell('${entry.key + 1}', center: true),
                  _tableCell(entry.value.name),
                  _tableCell(
                    '${_money(entry.value.price)} ${invoice.currency}',
                    center: true,
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsTable() {
    final rows = invoice.items
        .map(
          (item) => _InvoiceLine(
            name: item.productName.isEmpty ? '-' : item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            total: item.lineTotal,
          ),
        )
        .toList();

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.1),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _tableCell('productName'.tr, bold: true),
            _tableCell('quantity'.tr, bold: true, center: true),
            _tableCell('price'.tr, bold: true, center: true),
            _tableCell('total'.tr, bold: true, center: true),
          ],
        ),
        ...rows.map(
          (item) => TableRow(
            children: [
              _tableCell(item.name),
              _tableCell(item.quantity.toString(), center: true),
              _tableCell(
                '${_money(item.unitPrice)} ${invoice.currency}',
                center: true,
              ),
              _tableCell(
                '${_money(item.total)} ${invoice.currency}',
                bold: true,
                center: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell(
    String text, {
    bool bold = false,
    bool center = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _total(String label, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14.sp : 12.sp,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            '${_money(value)} ${invoice.currency}',
            style: TextStyle(
              fontSize: bold ? 14.sp : 12.sp,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLine {
  const _InvoiceLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
}

class MaintenanceInvoicePdfBuilder {
  MaintenanceInvoicePdfBuilder._();

  static final PdfColor _brandColor = PdfColor.fromHex('#6B65BD');
  static final PdfColor _borderColor = PdfColor.fromHex('#D1D5DB');
  static final PdfColor _textColor = PdfColor.fromHex('#111827');
  static final PdfColor _mutedColor = PdfColor.fromHex('#6B7280');
  static final PdfColor _rowColor = PdfColor.fromHex('#F9FAFB');

  static Future<pw.Font> _regular() async {
    final data =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _bold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static String _money(double value) => NumberFormat('#,##0.00').format(value);

  static String _currency(MaintenanceInvoiceModel invoice) => invoice.currency;

  static String _amount(
    MaintenanceInvoiceModel invoice,
    double value,
  ) =>
      '${_money(value)} ${_currency(invoice)}';

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data = await rootBundle.load('assets/images/dark_Logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> build(MaintenanceInvoiceModel invoice) async {
    final regular = await _regular();
    final bold = await _bold();
    final logo = await _logo();
    final productRows = invoice.items.isEmpty
        ? [
            ['-', '-', '-', 'لا توجد منتجات أو قطع غيار', '-']
          ]
        : invoice.items
            .asMap()
            .entries
            .map(
              (entry) => [
                _amount(invoice, entry.value.lineTotal),
                _amount(invoice, entry.value.unitPrice),
                '${entry.value.quantity}',
                entry.value.productName,
                '${entry.key + 1}',
              ],
            )
            .toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(
            font: regular,
            fontSize: 12,
            color: _textColor,
          ),
        ),
        build: (_) => [
          _purchaseHeader(invoice: invoice, logo: logo, bold: bold),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 10, bottom: 10),
            height: 1.3,
            color: _brandColor,
          ),
          pw.Center(
            child: pw.Text(
              'فاتورة صيانة',
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 8),
          _purchaseMetaBox(
            invoice: invoice,
            bold: bold,
          ),
          pw.SizedBox(height: 12),
          _purchaseDataTable(
            headers: const ['الإجمالي', 'السعر', 'الكمية', 'اسم المنتج', '#'],
            data: productRows,
            bold: bold,
            rtlColumns: const {3},
            columnWidths: const {
              0: pw.FlexColumnWidth(1.3),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(0.8),
              3: pw.FlexColumnWidth(2.8),
              4: pw.FlexColumnWidth(0.45),
            },
          ),
          if (invoice.services.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _sectionTitle('الخدمات المنفذة', bold),
            pw.SizedBox(height: 4),
            _purchaseDataTable(
              headers: const ['السعر', 'الخدمة', '#'],
              data: invoice.services
                  .asMap()
                  .entries
                  .map(
                    (entry) => [
                      _amount(invoice, entry.value.price),
                      entry.value.name,
                      '${entry.key + 1}',
                    ],
                  )
                  .toList(),
              bold: bold,
              rtlColumns: const {1},
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(4.2),
                2: pw.FlexColumnWidth(0.45),
              },
            ),
          ],
          if (invoice.payments.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _sectionTitle('تفاصيل الدفعات', bold),
            pw.SizedBox(height: 4),
            _purchaseDataTable(
              headers: const ['ملاحظة', 'المبلغ', 'النوع', 'التاريخ', '#'],
              data: invoice.payments
                  .asMap()
                  .entries
                  .map(
                    (entry) => [
                      entry.value.note ?? '-',
                      '${_money(entry.value.amount)} ${entry.value.currency}',
                      _paymentLabel(entry.value.method),
                      _shortDate(entry.value.createdAt),
                      '${entry.key + 1}',
                    ],
                  )
                  .toList(),
              bold: bold,
              rtlColumns: const {0, 2},
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.3),
                4: pw.FlexColumnWidth(0.45),
              },
            ),
          ],
          pw.SizedBox(height: 12),
          _purchaseTotals(invoice: invoice, bold: bold),
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _sectionTitle('ملاحظات', bold),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: pw.BoxDecoration(
                color: _rowColor,
                border: pw.Border.all(color: _borderColor),
              ),
              child: pw.Text(
                invoice.notes,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
          _purchaseFooter(),
        ],
      ),
    );
    return doc.save();
  }

  static String _paymentLabel(String method) {
    switch (method) {
      case 'visa':
        return 'فيزا';
      case 'bank_transfer':
        return 'حوالة';
      default:
        return 'كاش';
    }
  }

  static pw.Widget _purchaseHeader({
    required MaintenanceInvoiceModel invoice,
    required pw.MemoryImage? logo,
    required pw.Font bold,
  }) {
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
                  data: invoice.qrPayload,
                  width: 64,
                  height: 64,
                  drawText: false,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.invoiceNumber,
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
                'دكتور بايك - فاتورة صيانة',
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

  static pw.Widget _purchaseMetaBox({
    required MaintenanceInvoiceModel invoice,
    required pw.Font bold,
  }) {
    final debtLabel = invoice.hasDebt
        ? 'دين متبقٍ: ${_amount(invoice, invoice.debtAmount)}'
        : invoice.paymentStatus == 'paid'
            ? 'لا يوجد دين'
            : 'غير مدفوع بعد: ${_amount(invoice, invoice.remainingAmount)}';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.FlexColumnWidth(),
          },
          children: [
            _metaRow(
              left: _metaLine('التاريخ', invoice.invoiceDateDisplay, bold),
              right: _metaLine('رقم الفاتورة', invoice.invoiceNumber, bold,
                  valueLtr: true),
            ),
            _metaRow(
              left: _metaLine('نوع الطرف', invoice.customerTypeLabel, bold),
              right: _metaLine('الطرف', invoice.customerName, bold),
            ),
            _metaRow(
              left: _metaLine(
                'العنوان',
                _dash(invoice.customerAddress),
                bold,
              ),
              right: _metaLine(
                'الهاتف',
                _dash(invoice.customerPhone),
                bold,
                valueLtr: true,
              ),
            ),
            _metaRow(
              left: _metaLine('حالة الدفع', invoice.paymentStatusLabel, bold),
              right: _metaLine(
                'حالة الصيانة',
                invoice.maintenanceStatusLabel,
                bold,
              ),
            ),
            _metaRow(
              left: _metaLine(
                'موعد التسليم',
                _dash(invoice.receiptDateTimeDisplay),
                bold,
              ),
              right: _metaLine('حالة الدين', debtLabel, bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _metaRow({
    required pw.Widget left,
    required pw.Widget right,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(right: 16, bottom: 5),
          child: left,
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 5),
          child: right,
        ),
      ],
    );
  }

  static pw.Widget _metaLine(
    String label,
    String value,
    pw.Font bold, {
    bool valueLtr = false,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(': $label', style: pw.TextStyle(font: bold)),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Text(
              value,
              textDirection:
                  valueLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: PdfColor.fromHex('#374151')),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _purchaseDataTable({
    required List<String> headers,
    required List<List<String>> data,
    required pw.Font bold,
    required Set<int> rtlColumns,
    required Map<int, pw.TableColumnWidth> columnWidths,
  }) {
    final alignments = <int, pw.Alignment>{
      for (var i = 0; i < headers.length; i++)
        i: rtlColumns.contains(i)
            ? pw.Alignment.centerRight
            : pw.Alignment.center,
    };

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      tableDirection: pw.TextDirection.ltr,
      headerDirection: pw.TextDirection.rtl,
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: _borderColor, width: 0.8),
      cellPadding: const pw.EdgeInsets.all(5),
      headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _brandColor),
      oddRowDecoration: pw.BoxDecoration(color: _rowColor),
      cellAlignments: alignments,
      headerAlignments: alignments,
      cellBuilder: (index, data, rowNum) => pw.Text(
        data.toString(),
        textDirection: rtlColumns.contains(index)
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        textAlign: rtlColumns.contains(index)
            ? pw.TextAlign.right
            : pw.TextAlign.center,
        style: pw.TextStyle(
          font: rtlColumns.contains(index) ? null : bold,
          fontSize: rtlColumns.contains(index) ? 11 : 10.5,
        ),
      ),
    );
  }

  static pw.Widget _purchaseTotals({
    required MaintenanceInvoiceModel invoice,
    required pw.Font bold,
  }) {
    final rows = <List<Object?>>[
      ['الإجمالي الفرعي', invoice.partsTotal + invoice.laborCost, null],
      ['الخصم', invoice.discount, null],
      ['الضريبة', 0.0, null],
      ['إجمالي الفاتورة', invoice.invoiceTotal, 'total'],
      ['المبلغ المدفوع', invoice.paidAmount, 'paid'],
      ['المتبقي', invoice.remainingAmount, 'remaining'],
    ];

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 235,
        child: pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Table(
            border: pw.TableBorder.all(color: _borderColor, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.05),
              1: pw.FlexColumnWidth(1.2),
            },
            children: rows.map((row) {
              final kind = row[2] as String?;
              final valueColor = kind == 'paid'
                  ? PdfColors.green800
                  : kind == 'remaining' && (row[1] as double) > 0
                      ? PdfColors.orange800
                      : _textColor;
              return pw.TableRow(
                decoration: kind == 'total'
                    ? pw.BoxDecoration(color: PdfColor.fromHex('#E5E7EB'))
                    : null,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      _amount(invoice, row[1] as double),
                      textDirection: pw.TextDirection.ltr,
                      style: pw.TextStyle(
                        font: kind == null ? null : bold,
                        color: valueColor,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      row[0] as String,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: kind == 'total' ? bold : null),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: bold, fontSize: 12),
      ),
    );
  }

  static pw.Widget _purchaseFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor)),
      ),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(
          children: [
            pw.Text(
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(fontSize: 9, color: _mutedColor),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                'هذه نسخة مطبوعة من فاتورة صيانة من نظام دكتور بايك تم إنشاؤها بتاريخ',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 9, color: _mutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dash(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? '—' : clean;
  }

  static String _shortDate(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return '—';
    final parsed = DateTime.tryParse(clean);
    return parsed == null ? clean : DateFormat('yyyy-MM-dd').format(parsed);
  }
}
