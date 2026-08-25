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
    var paymentColor = PdfColors.red800;
    if (invoice.paymentStatus == 'paid') {
      paymentColor = PdfColors.green800;
    } else if (invoice.paymentStatus == 'partial') {
      paymentColor = PdfColors.orange800;
    }
    final rows = invoice.items.isEmpty
        ? [
            ['-', 'لا توجد منتجات أو قطع غيار', '-', '-', '-']
          ]
        : invoice.items
            .asMap()
            .entries
            .map(
              (entry) => [
                '${entry.key + 1}',
                entry.value.productName,
                '${entry.value.quantity}',
                '${_money(entry.value.unitPrice)} ${invoice.currency}',
                '${_money(entry.value.lineTotal)} ${invoice.currency}',
              ],
            )
            .toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'دكتور بايك - فاتورة صيانة',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 22,
                    color: PdfColors.deepPurple600,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: invoice.qrPayload,
                width: 62,
                height: 62,
                drawText: false,
              ),
              pw.SizedBox(width: 10),
              if (logo != null) pw.Image(logo, height: 68),
            ],
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 10, bottom: 12),
            height: 1.4,
            color: PdfColors.deepPurple600,
          ),
          pw.Center(
            child: pw.Text(
              'maintenanceInvoice'.tr,
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 12),
          _detailsTable(
            bold: bold,
            rows: [
              ['billNumber'.tr, invoice.invoiceNumber, null],
              ['maintenanceNumber'.tr, '#${invoice.maintenanceId}', null],
              ['date'.tr, invoice.invoiceDateDisplay, null],
              ['status'.tr, invoice.maintenanceStatusLabel, null],
              ['invoiceStatus'.tr, invoice.paymentStatusLabel, paymentColor],
              ['buyerName'.tr, invoice.customerName, null],
              ['phoneNumberTitle'.tr, invoice.customerPhone ?? '-', null],
              ['العنوان', invoice.customerAddress ?? '-', null],
              ['deliveryDate'.tr, invoice.receiptDateTimeDisplay, null],
              [
                'حالة الدين',
                invoice.hasDebt
                    ? 'دين متبقٍ ${_money(invoice.debtAmount)} ${invoice.currency}'
                    : invoice.paymentStatus == 'paid'
                        ? 'لا يوجد دين - مدفوعة بالكامل'
                        : 'لم يتم دفع كامل الفاتورة بعد - المتبقي ${_money(invoice.remainingAmount)} ${invoice.currency}',
                invoice.hasDebt
                    ? PdfColors.orange800
                    : invoice.paymentStatus == 'paid'
                        ? PdfColors.green800
                        : PdfColors.red800,
              ],
            ],
          ),
          pw.SizedBox(height: 14),
          if (invoice.services.isNotEmpty) ...[
            pw.Text('الخدمات المنفذة', style: pw.TextStyle(font: bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'الخدمة', 'السعر'],
              data: invoice.services
                  .asMap()
                  .entries
                  .map(
                    (entry) => [
                      '${entry.key + 1}',
                      entry.value.name,
                      '${_money(entry.value.price)} ${invoice.currency}',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.deepPurple600),
              cellAlignment: pw.Alignment.centerRight,
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Text('المنتجات وقطع الغيار', style: pw.TextStyle(font: bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'productName'.tr,
              'quantity'.tr,
              'price'.tr,
              'total'.tr
            ],
            data: rows,
            headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.deepPurple600),
            cellAlignment: pw.Alignment.centerRight,
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 210,
              child: pw.TableHelper.fromTextArray(
                data: [
                  [
                    'maintenancePartsTotal'.tr,
                    '${_money(invoice.partsTotal)} ${invoice.currency}'
                  ],
                  [
                    'maintenanceLaborCost'.tr,
                    '${_money(invoice.laborCost)} ${invoice.currency}'
                  ],
                  [
                    'discount'.tr,
                    '${_money(invoice.discount)} ${invoice.currency}'
                  ],
                  [
                    'totalBill'.tr,
                    '${_money(invoice.invoiceTotal)} ${invoice.currency}'
                  ],
                  [
                    'paidAmount'.tr,
                    '${_money(invoice.paidAmount)} ${invoice.currency}'
                  ],
                  [
                    'remainingAmount'.tr,
                    '${_money(invoice.remainingAmount)} ${invoice.currency}'
                  ],
                ],
                cellAlignment: pw.Alignment.centerRight,
              ),
            ),
          ),
          if (invoice.payments.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('تفاصيل الدفع', style: pw.TextStyle(font: bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              data: invoice.payments
                  .map(
                    (payment) => [
                      _paymentLabel(payment.method),
                      '${_money(payment.amount)} ${payment.currency}',
                      payment.note ?? '-',
                      payment.createdAt ?? '-',
                    ],
                  )
                  .toList(),
              headers: const ['طريقة الدفع', 'المبلغ', 'ملاحظة', 'التاريخ'],
              headerStyle: pw.TextStyle(font: bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.deepPurple600),
              cellAlignment: pw.Alignment.centerRight,
            ),
          ],
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('ملاحظات الصيانة', style: pw.TextStyle(font: bold)),
            pw.SizedBox(height: 5),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(invoice.notes),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تم إنشاء هذه الفاتورة من نظام دكتور بايك',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                textDirection: pw.TextDirection.ltr,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
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

  static pw.Widget _detailsTable({
    required pw.Font bold,
    required List<List<Object?>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell('القيمة', bold: bold, align: pw.Alignment.centerLeft),
            _cell('البيان', bold: bold, align: pw.Alignment.centerRight),
          ],
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: [
              _cell(
                (row[1] as String?)?.trim().isEmpty == true
                    ? '-'
                    : (row[1] as String? ?? '-'),
                align: pw.Alignment.centerLeft,
                color: row[2] as PdfColor?,
                bold: row[2] == null ? null : bold,
              ),
              _cell(row[0] as String, bold: bold),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.Font? bold,
    PdfColor? color,
    pw.Alignment align = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold, color: color),
      ),
    );
  }
}
