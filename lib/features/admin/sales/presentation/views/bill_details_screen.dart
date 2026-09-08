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

import '../../../../../routes/app_routes.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../../../maintenance/domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../../maintenance/presentation/widgets/maintenance_invoice_sheet.dart';
import '../../data/models/invoice_model.dart';
import '../controllers/sales_controller.dart';
import '../widgets/invoice_package_expandable_line.dart';

import '../../../../../core/helpers/app_failure_notice.dart';

class BillDetailsScreen extends GetView<SalesController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  String _dash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'billDetails',
        action: false,
        actions: [
          IconButton(
            tooltip: 'edit'.tr,
            onPressed: () => controller.openEditInstantSaleFromInvoice(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
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

          return ColoredBox(
            color: ThemeService.isDark.value
                ? AppColors.darkColor
                : const Color(0xFFF7F8FC),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
              children: [
                _SalesInvoiceHero(invoice: invoice),
                if (invoice.salesOrderId != null) ...[
                  SizedBox(height: 10.h),
                  _SalesOrderLinkCard(
                      orderId: invoice.salesOrderId!,
                      serial: invoice.salesOrderSerial),
                ],
                if (invoice.maintenanceId != null) ...[
                  SizedBox(height: 10.h),
                  _MaintenanceInvoiceLinkCard(
                      maintenanceId: invoice.maintenanceId!,
                      invoiceNumber: invoice.maintenanceInvoiceNumber),
                ],
                SizedBox(height: 12.h),
                _SalesInfoGrid(invoice: invoice, dash: _dash),
                SizedBox(height: 18.h),
                const _SalesSectionTitle(
                    icon: Icons.shopping_bag_outlined,
                    title: 'المنتجات المباعة'),
                SizedBox(height: 9.h),
                if (invoice.isPackageSale &&
                    invoice.packageComponentLines.isNotEmpty)
                  InvoicePackageExpandableLine(invoice: invoice)
                else
                  _SalesProductCard(
                      image: invoice.productImage,
                      name: invoice.displayProductTitle,
                      quantity: invoice.quantity.toString(),
                      price: invoice.cost.toString(),
                      total: invoice.subtotal),
                if (!invoice.isPackageSale)
                  ...invoice.subProducts.map((sub) => Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: _SalesProductCard(
                            image: sub.productImage,
                            name: sub.displayProductName,
                            quantity: sub.quantity,
                            price: sub.cost,
                            total: sub.subtotal),
                      )),
                if (invoice.additionalProductLines.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  const _SalesSectionTitle(
                      icon: Icons.add_box_outlined, title: 'منتجات إضافية'),
                  SizedBox(height: 8.h),
                  ...invoice.additionalProductLines.map((sub) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _SalesProductCard(
                            image: sub.productImage,
                            name: sub.displayProductName,
                            quantity: sub.quantity,
                            price: sub.cost,
                            total: sub.subtotal),
                      )),
                ],
                _InvoiceAdditionalNotesSection(notes: invoice.additionalNotes),
                SizedBox(height: 12.h),
                _InvoiceTotalsSection(
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
                SizedBox(height: 14.h),
                _InvoiceHistorySection(invoice: invoice),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceHistorySection extends StatefulWidget {
  const _InvoiceHistorySection({required this.invoice});

  final InvoiceModel invoice;

  @override
  State<_InvoiceHistorySection> createState() => _InvoiceHistorySectionState();
}

class _InvoiceHistorySectionState extends State<_InvoiceHistorySection> {
  bool isOpen = false;
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final history = widget.invoice.history;
    final visible =
        showAll || history.length <= 3 ? history : history.take(3).toList();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => isOpen = !isOpen),
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                children: [
                  const Expanded(
                    child: _SalesTileTitle(
                      icon: Icons.history_rounded,
                      title: 'سجل الفاتورة',
                    ),
                  ),
                  if (history.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${history.length}',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  SizedBox(width: 6.w),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            SizedBox(height: 10.h),
            if (history.isEmpty)
              Text(
                'لا توجد حركات محفوظة لهذه الفاتورة',
                style: TextStyle(
                  color: const Color(0xFF7A8092),
                  fontSize: 11.sp,
                ),
              )
            else
              ...visible.map((entry) => _InvoiceHistoryTile(entry)),
            if (history.length > 3)
              TextButton.icon(
                onPressed: () => setState(() => showAll = !showAll),
                icon: Icon(
                  showAll
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.more_horiz_rounded,
                ),
                label: Text(showAll ? 'عرض أقل' : 'عرض كل السجل'),
              ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceHistoryTile extends StatelessWidget {
  const _InvoiceHistoryTile(this.entry);

  final InvoiceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _historyColor(entry.action);
    final details = _historyDetails(entry);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              shape: BoxShape.circle,
            ),
            child: Icon(_historyIcon(entry.action), color: color, size: 18.sp),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      color: const Color(0xFF20243D),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    [
                      if (entry.actorName?.trim().isNotEmpty == true)
                        entry.actorName!.trim(),
                      if (entry.occurredAt?.trim().isNotEmpty == true)
                        _formatInvoiceDate(entry.occurredAt!),
                    ].join(' • '),
                    style: TextStyle(
                      color: const Color(0xFF7A8092),
                      fontSize: 10.sp,
                    ),
                  ),
                  if (entry.createdByName?.trim().isNotEmpty == true) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'أضافها أولًا: ${entry.createdByName}',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (entry.description?.trim().isNotEmpty == true) ...[
                    SizedBox(height: 5.h),
                    Text(entry.description!, style: TextStyle(fontSize: 10.sp)),
                  ],
                  if (details.isNotEmpty) ...[
                    SizedBox(height: 7.h),
                    ...details.map(
                      (line) => Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: const Color(0xFF4B5166),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _historyDetails(InvoiceHistoryEntry entry) {
  final before = entry.before;
  final after = entry.after;
  final result = <String>[];

  String value(Map<String, dynamic>? map, String key) => '${map?[key] ?? ''}';
  void addChange(String label, String key) {
    final oldValue = value(before, key);
    final newValue = value(after, key);
    if (before != null && after != null && oldValue != newValue) {
      result.add('$label: $oldValue ← $newValue');
    }
  }

  addChange('الإجمالي', 'total_cost');
  addChange('المدفوع', 'paid_amount');
  addChange('المشتري', 'buyer_name');
  addChange('الصندوق', 'payment_box_name');
  addChange('الملاحظات', 'notes');

  final oldLines = _historyLineSummary(before?['lines']);
  final newLines = _historyLineSummary(after?['lines']);
  if (before != null && after != null && oldLines != newLines) {
    if (oldLines.isNotEmpty) result.add('قبل: $oldLines');
    if (newLines.isNotEmpty) result.add('بعد: $newLines');
  } else if (before == null && newLines.isNotEmpty) {
    result.add('المنتجات: $newLines');
  }

  if (result.isEmpty && entry.amount?.trim().isNotEmpty == true) {
    result.add('القيمة: ${entry.amount}');
  }
  return result;
}

String _historyLineSummary(dynamic raw) {
  if (raw is! List) return '';
  return raw.whereType<Map>().map((line) {
    final name = '${line['name'] ?? '-'}';
    final quantity = '${line['quantity'] ?? 0}';
    final price = '${line['unit_price'] ?? 0}';
    return '$name ×$quantity ($price)';
  }).join('، ');
}

Color _historyColor(String action) {
  if (action.contains('cancel')) return const Color(0xFFDC2626);
  if (action.contains('update') || action.contains('edit')) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF16865B);
}

IconData _historyIcon(String action) {
  if (action.contains('cancel')) return Icons.cancel_outlined;
  if (action.contains('update') || action.contains('edit')) {
    return Icons.edit_outlined;
  }
  if (action.contains('suspended')) return Icons.playlist_add_check_rounded;
  return Icons.add_circle_outline_rounded;
}

class _SalesInvoiceHero extends StatelessWidget {
  const _SalesInvoiceHero({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final cancelled = invoice.displaySaleStatus == 'ملغى';
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B3D), Color(0xFF6B65BD)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فاتورة بيع',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12.sp)),
                    Text(invoice.invoiceNumber,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 21.sp,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              _InvoicePrintActions(invoice: invoice),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 18, color: Colors.white70),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _formatInvoiceDate(invoice.invoiceDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color:
                      (cancelled ? Colors.redAccent : const Color(0xFF33C481))
                          .withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        cancelled ? Colors.redAccent : const Color(0xFF55D99B),
                  ),
                ),
                child: Text(
                  invoice.displaySaleStatus,
                  style: TextStyle(
                    color: cancelled
                        ? Colors.red.shade100
                        : const Color(0xFFBDF5D8),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                  child:
                      _HeroValue(label: 'الإجمالي', value: invoice.totalCost)),
              Container(width: 1, height: 38.h, color: Colors.white24),
              Expanded(
                  child:
                      _HeroValue(label: 'المدفوع', value: invoice.paidAmount)),
              Container(width: 1, height: 38.h, color: Colors.white24),
              Expanded(
                  child: _HeroValue(
                      label: 'المتبقي',
                      value: invoice.remainingAmount,
                      warning:
                          (double.tryParse(invoice.remainingAmount) ?? 0) > 0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue(
      {required this.label, required this.value, this.warning = false});
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 10.sp)),
        SizedBox(height: 4.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: warning ? const Color(0xFFFFD166) : Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900)),
      ]);
}

class _SalesInfoGrid extends StatelessWidget {
  const _SalesInfoGrid({required this.invoice, required this.dash});
  final InvoiceModel invoice;
  final String Function(String?) dash;

  @override
  Widget build(BuildContext context) => Column(children: [
        _SalesInfoCard(
          icon: Icons.person_outline_rounded,
          title: 'بيانات المشتري',
          items: [
            MapEntry('الاسم', dash(invoice.buyerName)),
            MapEntry('الصفة', invoice.displayBuyerTypeLabel),
            MapEntry('الهاتف', dash(invoice.buyerPhone ?? invoice.phone)),
            if (dash(invoice.buyerAddress ?? invoice.address) != '-')
              MapEntry(
                  'العنوان', dash(invoice.buyerAddress ?? invoice.address)),
          ],
        ),
        SizedBox(height: 10.h),
        _SalesInfoCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'بيانات الدفع',
          items: [
            MapEntry('نوع البيع', invoice.displaySaleKindLabel),
            MapEntry('طريقة الدفع', dash(invoice.paymentMethod)),
            if (invoice.displayPaymentBox != '-')
              MapEntry('الصندوق', invoice.displayPaymentBox),
          ],
        ),
      ]);
}

class _SalesInfoCard extends StatelessWidget {
  const _SalesInfoCard(
      {required this.icon, required this.title, required this.items});
  final IconData icon;
  final String title;
  final List<MapEntry<String, String>> items;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE8EAF2))),
        child: Column(children: [
          _SalesTileTitle(icon: icon, title: title),
          SizedBox(height: 10.h),
          ...items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 92.w,
                          child: Text(item.key,
                              style: TextStyle(
                                  color: const Color(0xFF7A8092),
                                  fontSize: 11.sp))),
                      Expanded(
                          child: Text(item.value,
                              style: TextStyle(
                                  color: const Color(0xFF20243D),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700))),
                    ]),
              ))
        ]),
      );
}

class _SalesTileTitle extends StatelessWidget {
  const _SalesTileTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, color: AppColors.primaryColor, size: 19.sp)),
        SizedBox(width: 9.w),
        Text(title,
            style: TextStyle(
                color: const Color(0xFF20243D),
                fontSize: 14.sp,
                fontWeight: FontWeight.w900)),
      ]);
}

class _SalesSectionTitle extends StatelessWidget {
  const _SalesSectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) =>
      _SalesTileTitle(icon: icon, title: title);
}

class _SalesProductCard extends StatelessWidget {
  const _SalesProductCard(
      {required this.image,
      required this.name,
      required this.quantity,
      required this.price,
      required this.total});
  final String image;
  final String name;
  final String quantity;
  final String price;
  final String total;

  void _openImage(BuildContext context) {
    final original = ShowNetImage.getPhoto(image);
    if (image.trim().isEmpty || image == 'no image') return;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق الصورة',
      barrierColor: Colors.black.withValues(alpha: .82),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => FullScreenZoomImage(imageUrl: original),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: const Color(0xFFE8EAF2))),
        child: Row(children: [
          GestureDetector(
            onTap: () => _openImage(context),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: Image.network(ShowNetImage.getThumbnailPhoto(image),
                    width: 68.w,
                    height: 68.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 68.w,
                        height: 68.w,
                        color: const Color(0xFFF0F1F6),
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey)))),
          ),
          SizedBox(width: 11.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: const Color(0xFF20243D),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 8.h),
                Wrap(spacing: 6.w, runSpacing: 5.h, children: [
                  _ProductPill(label: 'الكمية', value: quantity),
                  _ProductPill(label: 'السعر', value: price),
                ]),
              ])),
          SizedBox(width: 8.w),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('المجموع',
                style:
                    TextStyle(color: const Color(0xFF8A90A2), fontSize: 9.sp)),
            SizedBox(height: 4.h),
            Text(total,
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900)),
          ]),
        ]),
      );
}

class _ProductPill extends StatelessWidget {
  const _ProductPill({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
        decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.darkColor
                : const Color(0xFFF3F2FA),
            borderRadius: BorderRadius.circular(7.r)),
        child: Text('$label: $value',
            style: TextStyle(
                color: const Color(0xFF555B70),
                fontSize: 9.sp,
                fontWeight: FontWeight.w600)),
      );
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

  Future<bool?> _chooseImageMode(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صور المنتجات'),
        content: const Text('اختر نسخة الفاتورة المطلوبة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('بدون صور'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.image_outlined),
            label: const Text('مع الصور'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final includeImages = await _chooseImageMode(context);
    if (includeImages == null) return;
    final bytes = await SalesInvoicePdfBuilder.build(
      invoice,
      includeProductImages: includeImages,
    );
    await Printing.sharePdf(bytes: bytes, filename: _fileName);
  }

  Future<void> _printPdf(BuildContext context) async {
    final includeImages = await _chooseImageMode(context);
    if (includeImages == null) return;
    final bytes = await SalesInvoicePdfBuilder.build(
      invoice,
      includeProductImages: includeImages,
    );
    await Printing.layoutPdf(
      name: _fileName,
      onLayout: (_) async => bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InvoiceHeroAction(
          tooltip: 'pdf'.tr,
          onPressed: () => _sharePdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
        SizedBox(width: 6.w),
        _InvoiceHeroAction(
          tooltip: 'print'.tr,
          onPressed: () => _printPdf(context),
          icon: const Icon(Icons.print_outlined),
        ),
      ],
    );
  }
}

class _InvoiceHeroAction extends StatelessWidget {
  const _InvoiceHeroAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(11.r),
          child: IconButton(
            constraints: BoxConstraints.tightFor(width: 38.w, height: 38.w),
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            color: Colors.white,
            iconSize: 19.sp,
            icon: icon,
          ),
        ),
      );
}

String _formatInvoiceDate(String raw) {
  final value = raw.trim();
  final date = DateTime.tryParse(value);
  if (date == null) return value.isEmpty ? '-' : value;

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour < 12 ? 'صباحًا' : 'مساءً';
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}'
      ' • $hour:${twoDigits(date.minute)} $period';
}

// ignore: unused_element
class _InvoiceHeaderCard extends StatelessWidget {
  const _InvoiceHeaderCard({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.saleKindLabel,
    required this.isAdjustmentSale,
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
  final String saleKindLabel;
  final bool isAdjustmentSale;
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
          _metaRow(
            context,
            'invoiceKind'.tr,
            saleKindLabel,
            highlight: isAdjustmentSale,
          ),
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

class _PdfLineRow {
  const _PdfLineRow({
    required this.index,
    required this.code,
    required this.name,
    required this.nameImage,
    this.variant,
    required this.quantity,
    required this.cost,
    required this.total,
    this.image,
  });

  final String index;
  final pw.ImageProvider? image;
  final String code;
  final String name;
  final pw.ImageProvider nameImage;
  final String? variant;
  final String quantity;
  final String cost;
  final String total;

  List<Object> visualCells(bool includeProductImages) {
    final cells = <Object>[
      index,
      if (includeProductImages) image ?? '-',
      code,
      _PdfProductNameCell(
        name: name,
        nameImage: nameImage,
        variant: variant,
      ),
      quantity,
      cost,
      total,
    ];

    return cells.reversed.toList();
  }
}

class _PdfProductNameCell {
  const _PdfProductNameCell({
    required this.name,
    required this.nameImage,
    this.variant,
  });

  final String name;
  final pw.ImageProvider nameImage;
  final String? variant;
}

class SalesInvoicePdfBuilder {
  SalesInvoicePdfBuilder._();

  static Future<pw.Font> _regular() async {
    try {
      return await PdfGoogleFonts.cairoRegular()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      final data =
          await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
      return pw.Font.ttf(data);
    }
  }

  static Future<pw.Font> _bold() async {
    try {
      return await PdfGoogleFonts.cairoBold()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      final data =
          await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
      return pw.Font.ttf(data);
    }
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

  static String _cleanPdfProductBaseName({
    required String preferredBaseName,
    required String fallbackName,
    String? variantLabel,
    String? sizeLabel,
    String? colorLabel,
  }) {
    var base = preferredBaseName.trim().isNotEmpty
        ? preferredBaseName.trim()
        : fallbackName.trim();
    if (base.isEmpty) return '-';

    for (final suffix in [
      variantLabel,
      [
        sizeLabel?.trim(),
        colorLabel?.trim(),
      ].where((part) => part != null && part.isNotEmpty).join(' / '),
      sizeLabel,
      colorLabel,
    ]) {
      final value = suffix?.trim();
      if (value == null || value.isEmpty) continue;
      base = base.replaceAll(' — $value', '').replaceAll(' - $value', '');
    }

    return base.trim().isEmpty ? '-' : base.trim();
  }

  static String? _pdfVariantLine({
    String? sizeLabel,
    String? colorLabel,
    String? variantLabel,
  }) {
    final variant = variantLabel?.trim();
    if (variant != null && variant.isNotEmpty) {
      return variant;
    }

    final parts = [
      sizeLabel?.trim(),
      colorLabel?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>().toList();

    return parts.isEmpty ? null : parts.join(' / ');
  }

  static Future<pw.ImageProvider> _productNameImage(String text) async {
    final value = text.trim().isEmpty ? '-' : text.trim();
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'Almarai',
          fontSize: 42,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.rtl,
      maxLines: 1,
    )..layout();

    final width = (painter.width + 12).ceil().clamp(24, 900);
    final height = (painter.height + 8).ceil().clamp(24, 160);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    painter.paint(canvas, const ui.Offset(6, 4));
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return pw.MemoryImage(data!.buffer.asUint8List());
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
    InvoiceModel invoice, {
    bool includeProductImages = false,
  }) async {
    final regular = await _regular();
    final bold = await _bold();
    final logo = await _logo();
    final rows = await _lineRows(
      invoice,
      includeProductImages: includeProductImages,
    );

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
                  'دكتور بايك - ${'salesInvoiceNonTaxTitle'.tr}',
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
              '${'salesInvoiceNonTaxTitle'.tr} ${invoice.invoiceNumber}',
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
          _itemsTable(
            rows: rows,
            regular: regular,
            bold: bold,
            includeProductImages: includeProductImages,
          ),
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

  static Future<List<_PdfLineRow>> _lineRows(
    InvoiceModel invoice, {
    required bool includeProductImages,
  }) async {
    final rows = <_PdfLineRow>[];

    Future<void> addLine({
      required String imageUrl,
      required String code,
      required String name,
      String? variant,
      required String quantity,
      required String cost,
      required String total,
    }) async {
      rows.add(
        _PdfLineRow(
          index: '${rows.length + 1}',
          image: includeProductImages ? await _productImage(imageUrl) : null,
          code: code.trim().isEmpty ? '-' : code,
          name: name,
          nameImage: await _productNameImage(name),
          variant: variant,
          quantity: quantity,
          cost: _money(cost),
          total: _money(total),
        ),
      );
    }

    if (invoice.isPackageSale) {
      await addLine(
        imageUrl: invoice.productImage,
        code: invoice.productCode ?? '-',
        name: _cleanPdfProductBaseName(
          preferredBaseName: invoice.displayProductNameOnly,
          fallbackName: invoice.displayProductTitle,
          sizeLabel: invoice.sizeLabel,
          colorLabel: invoice.colorLabel,
          variantLabel: invoice.variantLabel,
        ),
        variant: _pdfVariantLine(
          sizeLabel: invoice.sizeLabel,
          colorLabel: invoice.colorLabel,
          variantLabel: invoice.variantLabel,
        ),
        quantity: invoice.quantity,
        cost: invoice.cost,
        total: invoice.subtotal,
      );
      for (final sub in invoice.additionalProductLines) {
        await addLine(
          imageUrl: sub.productImage,
          code: sub.productCode ?? '-',
          name: _cleanPdfProductBaseName(
            preferredBaseName: sub.productNameBase?.trim().isNotEmpty == true
                ? sub.productNameBase!
                : sub.productName,
            fallbackName: sub.displayProductName,
            sizeLabel: sub.sizeLabel,
            colorLabel: sub.colorLabel,
            variantLabel: sub.variantLabel,
          ),
          variant: _pdfVariantLine(
            sizeLabel: sub.sizeLabel,
            colorLabel: sub.colorLabel,
            variantLabel: sub.variantLabel,
          ),
          quantity: sub.quantity,
          cost: sub.cost,
          total: sub.subtotal,
        );
      }
    } else {
      await addLine(
        imageUrl: invoice.productImage,
        code: invoice.productCode ?? '-',
        name: _cleanPdfProductBaseName(
          preferredBaseName: invoice.displayProductNameOnly,
          fallbackName: invoice.displayProductTitle,
          sizeLabel: invoice.sizeLabel,
          colorLabel: invoice.colorLabel,
          variantLabel: invoice.variantLabel,
        ),
        variant: _pdfVariantLine(
          sizeLabel: invoice.sizeLabel,
          colorLabel: invoice.colorLabel,
          variantLabel: invoice.variantLabel,
        ),
        quantity: invoice.quantity,
        cost: invoice.cost,
        total: invoice.subtotal,
      );
      for (final sub in invoice.subProducts) {
        await addLine(
          imageUrl: sub.productImage,
          code: sub.productCode ?? '-',
          name: _cleanPdfProductBaseName(
            preferredBaseName: sub.productNameBase?.trim().isNotEmpty == true
                ? sub.productNameBase!
                : sub.productName,
            fallbackName: sub.displayProductName,
            sizeLabel: sub.sizeLabel,
            colorLabel: sub.colorLabel,
            variantLabel: sub.variantLabel,
          ),
          variant: _pdfVariantLine(
            sizeLabel: sub.sizeLabel,
            colorLabel: sub.colorLabel,
            variantLabel: sub.variantLabel,
          ),
          quantity: sub.quantity,
          cost: sub.cost,
          total: sub.subtotal,
        );
      }
    }

    return rows;
  }

  static pw.Widget _itemsTable({
    required List<_PdfLineRow> rows,
    required pw.Font regular,
    required pw.Font bold,
    required bool includeProductImages,
  }) {
    final headers = [
      '#',
      if (includeProductImages) 'الصورة',
      'productCode'.tr,
      'productName'.tr,
      'quantity'.tr,
      'price'.tr,
      'total'.tr,
    ];
    final visualHeaders = headers.reversed.toList();
    final visualRows =
        rows.map((row) => row.visualCells(includeProductImages)).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
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
                  (cell) => cell is pw.ImageProvider
                      ? _imageCell(cell)
                      : cell is _PdfProductNameCell
                          ? _productNameCell(cell, font: regular)
                          : _tableCell(
                              cell.toString(),
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

  static pw.Widget _imageCell(pw.ImageProvider image) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(3),
      height: 42,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  }

  static pw.Widget _productNameCell(
    _PdfProductNameCell cell, {
    required pw.Font font,
  }) {
    final variant = cell.variant?.trim();

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(
              cell.nameImage,
              height: 15,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.centerRight,
            ),
            if (variant != null && variant.isNotEmpty) ...[
              pw.SizedBox(width: 4),
              pw.Text(
                variant,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: font,
                  color: PdfColors.grey600,
                  fontSize: 8.2,
                ),
              ),
            ],
          ],
        ),
      ),
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
      (failure) => AppFailureNotice.show(
        title: 'error'.tr,
        message: failure.errMessage,
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
