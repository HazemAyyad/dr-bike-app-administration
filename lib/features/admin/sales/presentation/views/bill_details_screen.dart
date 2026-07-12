import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../../../maintenance/domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../../maintenance/presentation/widgets/maintenance_invoice_sheet.dart';
import '../../../../employee/my_orders/widgets/row_text.dart';
import '../../data/models/invoice_model.dart';
import '../controllers/sales_controller.dart';
import '../widgets/invoice_package_expandable_line.dart';
import '../widgets/proudact_details_widget.dart';

class BillDetailsScreen extends GetView<SalesController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  String _dash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'billDetails', action: false),
      body: GetBuilder<SalesController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.invoiceModel == null) {
            return const Center(child: ShowNoData());
          }

          final invoice = controller.invoiceModel!;
          final fmt = NumberFormat('#,###.##');

          return CustomScrollView(
            slivers: [
              if (invoice.salesOrderId != null)
                SliverToBoxAdapter(
                  child: _SalesOrderLinkCard(
                    orderId: invoice.salesOrderId!,
                    serial: invoice.salesOrderSerial,
                  ),
                ),
              if (invoice.maintenanceId != null)
                SliverToBoxAdapter(
                  child: _MaintenanceInvoiceLinkCard(
                    maintenanceId: invoice.maintenanceId!,
                    invoiceNumber: invoice.maintenanceInvoiceNumber,
                  ),
                ),
              SliverToBoxAdapter(
                child: _InvoicePrintActions(invoice: invoice),
              ),
              SliverToBoxAdapter(
                child: _InvoiceHeaderCard(
                  invoiceNumber: _dash(invoice.invoiceNumber),
                  invoiceDate: _dash(invoice.invoiceDate),
                  buyerTypeLabel: invoice.displayBuyerTypeLabel,
                  buyerName: _dash(invoice.buyerName),
                  phone: _dash(invoice.buyerPhone ?? invoice.phone),
                  address: _dash(invoice.buyerAddress ?? invoice.address),
                  paymentMethod: _dash(invoice.paymentMethod),
                  paymentBoxName: invoice.displayPaymentBox,
                  saleStatus: invoice.displaySaleStatus,
                  notes: _dash(invoice.notes),
                  additionalNotes: invoice.additionalNotes,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.secondaryColor
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox.shrink(),
                      Flexible(child: RowText(title: 'productName')),
                      Flexible(child: RowText(title: 'quantity')),
                      Flexible(child: RowText(title: 'price')),
                      Flexible(child: RowText(title: 'total')),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 10.h)),
              if (invoice.isPackageSale &&
                  invoice.packageComponentLines.isNotEmpty)
                SliverToBoxAdapter(
                  child: InvoicePackageExpandableLine(invoice: invoice),
                )
              else if (invoice.isPackageSale)
                SliverToBoxAdapter(
                  child: ProudactDetailsWidget(
                    image: invoice.productImage,
                    cost: invoice.cost.toString(),
                    product: invoice.displayProductTitle,
                    quantity: invoice.quantity.toString(),
                    subtotal: invoice.subtotal,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return ProudactDetailsWidget(
                          image: invoice.productImage,
                          cost: invoice.cost.toString(),
                          product: invoice.displayProductTitle,
                          quantity: invoice.quantity.toString(),
                          subtotal: invoice.subtotal,
                        );
                      }
                      final sub = invoice.subProducts[index - 1];
                      return ProudactDetailsWidget(
                        image: sub.productImage,
                        cost: sub.cost.toString(),
                        product: sub.displayProductName,
                        quantity: sub.quantity.toString(),
                        subtotal: sub.subtotal,
                      );
                    },
                    childCount: 1 + invoice.subProducts.length,
                  ),
                ),
              if (invoice.isPackageSale &&
                  invoice.additionalProductLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 6.h),
                    child: Text(
                      'instantSaleAdditionalProducts'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            fontSize: 14.sp,
                          ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = invoice.additionalProductLines[index];
                      return ProudactDetailsWidget(
                        image: sub.productImage,
                        cost: sub.cost,
                        product: sub.displayProductName,
                        quantity: sub.quantity,
                        subtotal: sub.subtotal,
                      );
                    },
                    childCount: invoice.additionalProductLines.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _InvoiceAdditionalNotesSection(
                  notes: invoice.additionalNotes,
                ),
              ),
              SliverToBoxAdapter(
                child: _InvoiceTotalsSection(
                  subtotal: fmt.format(double.tryParse(invoice.subtotal) ?? 0),
                  discount: fmt.format(double.tryParse(invoice.discount) ?? 0),
                  notesTotal: fmt.format(
                    double.tryParse(invoice.additionalNotesTotal) ?? 0,
                  ),
                  tax: fmt.format(double.tryParse(invoice.tax) ?? 0),
                  paid: fmt.format(double.tryParse(invoice.paidAmount) ?? 0),
                  remaining:
                      fmt.format(double.tryParse(invoice.remainingAmount) ?? 0),
                  total: fmt.format(double.tryParse(invoice.totalCost) ?? 0),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          );
        },
      ),
    );
  }
}

class _InvoicePrintActions extends StatelessWidget {
  const _InvoicePrintActions({required this.invoice});

  final InvoiceModel invoice;

  String get _fileName {
    final safeNumber = invoice.invoiceNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return 'sales_invoice_$safeNumber.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              invoice.invoiceNumber,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'pdf'.tr,
            onPressed: () async {
              final bytes = await SalesInvoicePdfBuilder.build(invoice);
              await Printing.sharePdf(bytes: bytes, filename: _fileName);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'print'.tr,
            onPressed: () async {
              final bytes = await SalesInvoicePdfBuilder.build(invoice);
              await Printing.layoutPdf(
                name: _fileName,
                onLayout: (_) async => bytes,
              );
            },
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
    );
  }
}

class _InvoiceHeaderCard extends StatelessWidget {
  const _InvoiceHeaderCard({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.buyerTypeLabel,
    required this.buyerName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.paymentBoxName,
    required this.saleStatus,
    required this.notes,
    required this.additionalNotes,
  });

  final String invoiceNumber;
  final String invoiceDate;
  final String buyerTypeLabel;
  final String buyerName;
  final String phone;
  final String address;
  final String paymentMethod;
  final String paymentBoxName;
  final String saleStatus;
  final String notes;
  final List<InvoiceAdditionalNote> additionalNotes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _metaRow(context, 'billNumber'.tr, invoiceNumber),
          _metaRow(context, 'date'.tr, invoiceDate),
          _metaRow(
            context,
            'buyerTypeSale'.tr,
            buyerTypeLabel,
            highlight: true,
          ),
          _metaRow(context, 'buyerName'.tr, buyerName),
          _metaRow(context, 'phoneNumberTitle'.tr, phone),
          _metaRow(context, 'address'.tr, address),
          Divider(height: 16.h),
          _metaRow(context, 'paymentMethod'.tr, paymentMethod),
          if (paymentBoxName != '-')
            _metaRow(context, 'boxName'.tr, paymentBoxName, highlight: true),
          _metaRow(context, 'status'.tr, saleStatus),
          if (notes != '-' && additionalNotes.isEmpty)
            _metaRow(context, 'notes'.tr, notes),
        ],
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.customGreyColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    fontSize: highlight ? 13.sp : 12.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceAdditionalNotesSection extends StatelessWidget {
  const _InvoiceAdditionalNotesSection({required this.notes});

  final List<InvoiceAdditionalNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'additionalNotes'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                ),
          ),
          SizedBox(height: 6.h),
          ...notes.map(
            (note) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      note.text.trim().isEmpty ? '-' : note.text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${note.amount} ${'currency'.tr}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTotalsSection extends StatelessWidget {
  const _InvoiceTotalsSection({
    required this.subtotal,
    required this.discount,
    required this.notesTotal,
    required this.tax,
    required this.paid,
    required this.remaining,
    required this.total,
  });

  final String subtotal;
  final String discount;
  final String notesTotal;
  final String tax;
  final String paid;
  final String remaining;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1.h,
            width: double.infinity,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 10.h),
          _totalLine(context, 'subtotal'.tr, subtotal),
          _totalLine(context, 'discount'.tr, discount),
          if (notesTotal != '0')
            _totalLine(context, 'notesTotal'.tr, notesTotal),
          _totalLine(context, 'tax'.tr, tax),
          _totalLine(context, 'totalBill'.tr, total, bold: true),
          SizedBox(height: 4.h),
          _totalLine(context, 'paidAmount'.tr, paid),
          _totalLine(context, 'remainingAmount'.tr, remaining),
        ],
      ),
    );
  }

  Widget _totalLine(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 14.sp : 13.sp,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 14.sp : 13.sp,
                ),
          ),
        ],
      ),
    );
  }
}

class SalesInvoicePdfBuilder {
  SalesInvoicePdfBuilder._();

  static Future<pw.Font> _regular() async {
    final data =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _bold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data = await rootBundle.load('assets/images/dark_Logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _money(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return NumberFormat('#,##0.00').format(parsed ?? 0);
  }

  static Future<Uint8List> build(InvoiceModel invoice) async {
    final regular = await _regular();
    final bold = await _bold();
    final logo = await _logo();
    final rows = _lineRows(invoice);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'دكتور بايك - فاتورة مبيعات',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 21,
                    color: PdfColors.deepPurple600,
                  ),
                ),
              ),
              if (logo != null) pw.Image(logo, height: 88),
            ],
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8, bottom: 10),
            height: 1.3,
            color: PdfColors.deepPurple600,
          ),
          pw.Center(
            child: pw.Text(
              '${'instantSaleInvoice'.tr} ${invoice.invoiceNumber}',
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 8),
          _invoiceHeader(
            bold: bold,
            regular: regular,
            rows: [
              ['billNumber'.tr, invoice.invoiceNumber, null],
              ['date'.tr, invoice.invoiceDate, null],
              ['buyerTypeSale'.tr, invoice.displayBuyerTypeLabel, null],
              ['buyerName'.tr, invoice.displayTraderName, null],
              [
                'phoneNumberTitle'.tr,
                invoice.buyerPhone ?? invoice.phone ?? '-',
                null
              ],
              [
                'address'.tr,
                invoice.buyerAddress ?? invoice.address ?? '-',
                null
              ],
              ['paymentMethod'.tr, invoice.paymentMethod ?? '-', null],
            ],
          ),
          pw.SizedBox(height: 12),
          _itemsTable(rows: rows, regular: regular, bold: bold),
          if (invoice.additionalNotes.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'additionalNotes'.tr,
              style: pw.TextStyle(font: bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            ...invoice.additionalNotes.map(
              (note) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(note.text)),
                  pw.Text(_money(note.amount), style: pw.TextStyle(font: bold)),
                ],
              ),
            ),
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
                  ['subtotal'.tr, _money(invoice.subtotal)],
                  ['discount'.tr, _money(invoice.discount)],
                  if ((double.tryParse(invoice.additionalNotesTotal) ?? 0) > 0)
                    ['notesTotal'.tr, _money(invoice.additionalNotesTotal)],
                  ['tax'.tr, _money(invoice.tax)],
                  ['totalBill'.tr, _money(invoice.totalCost)],
                  ['paidAmount'.tr, _money(invoice.paidAmount)],
                  ['remainingAmount'.tr, _money(invoice.remainingAmount)],
                ],
              ),
            ),
          ),
          if (invoice.notes?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '${'notes'.tr}: ${invoice.notes}',
              style: pw.TextStyle(font: regular, fontSize: 10),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static List<List<String>> _lineRows(InvoiceModel invoice) {
    final rows = <List<String>>[];

    void addLine({
      required String code,
      required String name,
      required String quantity,
      required String cost,
      required String total,
    }) {
      rows.add([
        '${rows.length + 1}',
        code.trim().isEmpty ? '-' : code,
        name,
        quantity,
        _money(cost),
        _money(total),
      ]);
    }

    if (invoice.isPackageSale) {
      addLine(
        code: invoice.productCode ?? '-',
        name: invoice.displayProductTitle,
        quantity: invoice.quantity,
        cost: invoice.cost,
        total: invoice.subtotal,
      );
      for (final sub in invoice.additionalProductLines) {
        addLine(
          code: sub.productCode ?? '-',
          name: sub.displayProductName,
          quantity: sub.quantity,
          cost: sub.cost,
          total: sub.subtotal,
        );
      }
    } else {
      addLine(
        code: invoice.productCode ?? '-',
        name: invoice.displayProductTitle,
        quantity: invoice.quantity,
        cost: invoice.cost,
        total: invoice.subtotal,
      );
      for (final sub in invoice.subProducts) {
        addLine(
          code: sub.productCode ?? '-',
          name: sub.displayProductName,
          quantity: sub.quantity,
          cost: sub.cost,
          total: sub.subtotal,
        );
      }
    }

    return rows;
  }

  static pw.Widget _itemsTable({
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    final headers = [
      '#',
      'productCode'.tr,
      'productName'.tr,
      'quantity'.tr,
      'price'.tr,
      'total'.tr,
    ];
    final visualHeaders = headers.reversed.toList();
    final visualRows = rows.map((row) => row.reversed.toList()).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
      columnWidths: const {
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
          children: visualHeaders
              .map(
                (text) => _tableCell(
                  text,
                  font: bold,
                  color: PdfColors.white,
                  alignment: pw.Alignment.centerRight,
                ),
              )
              .toList(),
        ),
        ...visualRows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (text) => _tableCell(
                    text,
                    font: regular,
                    alignment: pw.Alignment.centerRight,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalsTable({
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: rows.map((row) {
        final isTotal = row.first == 'totalBill'.tr;
        return pw.TableRow(
          decoration:
              isTotal ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
          children: [
            _tableCell(
              row[1],
              font: isTotal ? bold : regular,
              alignment: pw.Alignment.centerLeft,
            ),
            _tableCell(
              row[0],
              font: isTotal ? bold : regular,
              alignment: pw.Alignment.centerRight,
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    required pw.Font font,
    PdfColor? color,
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: font, color: color, fontSize: 9),
      ),
    );
  }

  static pw.Widget _invoiceHeader({
    required pw.Font bold,
    required pw.Font regular,
    required List<List<Object?>> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 6,
        children: rows.map((row) {
          final value = (row[1] as String?)?.trim().isEmpty == true
              ? '-'
              : (row[1] as String? ?? '-');
          return pw.SizedBox(
            width: 235,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${row[0]}: ',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: bold, fontSize: 9.5),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: regular, fontSize: 9.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SalesOrderLinkCard extends StatelessWidget {
  const _SalesOrderLinkCard({
    required this.orderId,
    this.serial,
  });

  final int orderId;
  final String? serial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      child: Material(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.SALESORDERDETAILSCREEN,
            arguments: orderId,
          ),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20.sp, color: const Color(0xFF2563EB)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'salesOrderLinkedInvoice'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      Text(
                        serial ?? '#$orderId',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left,
                    color: const Color(0xFF2563EB), size: 22.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceInvoiceLinkCard extends StatelessWidget {
  const _MaintenanceInvoiceLinkCard({
    required this.maintenanceId,
    this.invoiceNumber,
  });

  final int maintenanceId;
  final String? invoiceNumber;

  Future<void> _open(BuildContext context) async {
    AppDependencyRegistry.ensureMaintenance();
    final result = await GetMaintenanceInvoiceUsecase(
      maintenanceRepository: Get.find<MaintenanceImplement>(),
    ).call(maintenanceId: maintenanceId.toString());

    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      ),
      (invoice) => showMaintenanceInvoiceSheet(context, invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      child: Material(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 20.sp,
                  color: const Color(0xFF16A34A),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'maintenanceInvoice'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      Text(
                        invoiceNumber?.trim().isNotEmpty == true
                            ? invoiceNumber!.trim()
                            : 'MNT-${maintenanceId.toString().padLeft(6, '0')}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: const Color(0xFF16A34A),
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
