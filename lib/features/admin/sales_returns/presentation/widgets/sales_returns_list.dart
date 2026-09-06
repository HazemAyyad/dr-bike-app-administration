import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/utils/instant_sale_display.dart';
import '../../data/sales_return_models.dart';
import '../controllers/sales_returns_controller.dart';
import '../utils/sales_return_invoice_pdf.dart';

const salesReturnColor = Color(0xFFB42318);
const salesReturnSurface = Color(0xFFFFF1F0);

class SalesReturnsList extends GetView<SalesReturnsController> {
  const SalesReturnsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.visibleReturns;
      if (controller.isReturnsLoading.value && rows.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (rows.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('لا توجد فواتير مرتجع مبيعات')),
        );
      }
      final groups = <String, List<SalesReturnRecord>>{};
      for (final row in rows) {
        groups.putIfAbsent(_returnDateKey(row.completedAt), () => []).add(row);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReturnsTableHeader(),
          for (var i = 0; i < groups.entries.length; i++) ...[
            if (i > 0) SizedBox(height: 14.h),
            _ReturnDateHeader(
              dateKey: groups.entries.elementAt(i).key,
              count: groups.entries.elementAt(i).value.length,
            ),
            ...groups.entries.elementAt(i).value.map(
                  (row) => _SalesReturnRow(record: row),
                ),
          ],
          SizedBox(height: 4.h),
        ],
      );
    });
  }
}

class _ReturnDateHeader extends StatelessWidget {
  const _ReturnDateHeader({required this.dateKey, required this.count});

  final String dateKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    final formatted = formatInstantSalesDateHeader(
      dateKey,
      invoiceCount: count,
    );
    final separator = formatted.lastIndexOf(' · ');
    final date = separator < 0 ? formatted : formatted.substring(0, separator);
    final bg = ThemeService.isDark.value
        ? salesReturnColor.withValues(alpha: .16)
        : salesReturnColor.withValues(alpha: .07);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        '$date · $count ${count == 1 ? 'فاتورة مرتجع' : 'فواتير مرتجع'}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: salesReturnColor,
          fontWeight: FontWeight.w700,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _ReturnsTableHeader extends StatelessWidget {
  const _ReturnsTableHeader();

  @override
  Widget build(BuildContext context) {
    final bg = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : const Color(0xFFEEF4FF);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          _ReturnHeaderCell('الفاتورة', flex: 2),
          _ReturnHeaderCell('التاريخ / الوقت', flex: 2),
          _ReturnHeaderCell('الإجمالي', flex: 2),
          _ReturnHeaderCell('القطع', flex: 2),
          _ReturnHeaderCell('الطرف', flex: 2),
          _ReturnHeaderCell('الحالة', flex: 3),
        ],
      ),
    );
  }
}

class _ReturnHeaderCell extends StatelessWidget {
  const _ReturnHeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      );
}

class _SalesReturnRow extends StatelessWidget {
  const _SalesReturnRow({required this.record});

  final SalesReturnRecord record;

  @override
  Widget build(BuildContext context) {
    final cancelled = record.isCancelled;
    final isDark = ThemeService.isDark.value;
    final background = cancelled
        ? Colors.red.withValues(alpha: .06)
        : (isDark ? AppColors.customGreyColor4 : Colors.white);
    return Material(
      color: background,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 11.h),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color:
                            cancelled ? Colors.grey.shade600 : salesReturnColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        cancelled ? 'مرتجع ملغى' : 'مرتجع مبيعات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      record.serialNumber,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: salesReturnColor,
                        decoration: TextDecoration.underline,
                        decorationColor: salesReturnColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_date(record.completedAt),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.sp)),
                    SizedBox(height: 2.h),
                    Text(_time(record.completedAt),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${record.totalAmount.toStringAsFixed(2)} ₪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cancelled ? Colors.red.shade700 : salesReturnColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${record.returnedQuantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp)),
                    Text('${record.itemsCount} صنف',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9.sp, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(record.isSeller ? 'مورد / تاجر' : 'زبون',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor)),
                    SizedBox(height: 2.h),
                    Text(record.partnerName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.sp)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReturnStatusChip(cancelled: cancelled),
                    SizedBox(width: 2.w),
                    _ReturnOperationInfo(record: record),
                    Icon(Icons.chevron_left_rounded,
                        size: 20.sp, color: salesReturnColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    final controller = Get.find<SalesReturnsController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<SalesReturnRecord?>(
          future: controller.loadReturnDetails(record.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final value = snapshot.data;
            if (value == null) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('تعذر تحميل تفاصيل المرتجع')),
              );
            }
            return _ReturnDetails(record: value);
          },
        ),
      ),
    );
  }

  String _date(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  String _time(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '—';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}

class _ReturnStatusChip extends StatelessWidget {
  const _ReturnStatusChip({required this.cancelled});

  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? Colors.red : const Color(0xFF1B8A4A);
    final label = cancelled ? 'ملغى' : 'فعال';
    return Tooltip(
      message: label,
      child: Container(
        width: 30.w,
        height: 30.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Icon(
          cancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
          size: 19.sp,
          color: color,
        ),
      ),
    );
  }
}

class _ReturnOperationInfo extends StatelessWidget {
  const _ReturnOperationInfo({required this.record});

  final SalesReturnRecord record;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'تفاصيل العملية',
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('تفاصيل عملية المرتجع'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ReturnInfoRow(
                      label: 'المعاد نقدًا',
                      value: '${record.cashRefundAmount.toStringAsFixed(2)} ₪'),
                  SizedBox(height: 8.h),
                  _ReturnInfoRow(
                      label: 'الرصيد المسجل',
                      value: '${record.creditAmount.toStringAsFixed(2)} ₪'),
                  SizedBox(height: 8.h),
                  _ReturnInfoRow(
                      label: 'صندوق الرد',
                      value: record.refundBoxName.isEmpty
                          ? '—'
                          : record.refundBoxName),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
          child: SizedBox(
            width: 28.w,
            height: 28.w,
            child: Icon(Icons.info_outline,
                size: 20.sp, color: AppColors.primaryColor),
          ),
        ),
      );
}

class _ReturnInfoRow extends StatelessWidget {
  const _ReturnInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

String _returnDateKey(String raw) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) return raw;
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}-$month-$day';
}

class _ReturnDetails extends StatelessWidget {
  const _ReturnDetails({required this.record});

  final SalesReturnRecord record;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        minChildSize: .45,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.all(16.r),
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_return_outlined,
                    color: salesReturnColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.serialNumber,
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.w900)),
                      Text(
                        record.isCancelled ? 'مرتجع ملغى' : 'مرتجع فعال',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: record.isCancelled
                              ? Colors.grey.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!record.isCancelled)
                  IconButton(
                    tooltip: 'تعديل المرتجع',
                    onPressed: () =>
                        Get.find<SalesReturnsController>().startEdit(record),
                    icon: const Icon(Icons.edit_outlined,
                        color: salesReturnColor),
                  ),
                if (!record.isCancelled)
                  IconButton(
                    tooltip: 'إلغاء المرتجع',
                    onPressed: () => _cancelReturn(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  ),
                IconButton(
                  tooltip: 'تنزيل / مشاركة فاتورة المرتجع',
                  onPressed: () async {
                    final bytes = await SalesReturnInvoicePdf.build(record);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: SalesReturnInvoicePdf.filename(record),
                    );
                  },
                  icon: const Icon(Icons.download_outlined,
                      color: salesReturnColor),
                ),
                IconButton(
                  tooltip: 'طباعة فاتورة المرتجع',
                  onPressed: () => Printing.layoutPdf(
                    name: SalesReturnInvoicePdf.filename(record),
                    onLayout: (_) => SalesReturnInvoicePdf.build(record),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: salesReturnColor),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            _info('الطرف', record.partnerName),
            _info(
                'إجمالي المرتجع', '${record.totalAmount.toStringAsFixed(2)} ₪'),
            _info('المعاد نقدًا',
                '${record.cashRefundAmount.toStringAsFixed(2)} ₪'),
            _info(
                'الرصيد المسجل', '${record.creditAmount.toStringAsFixed(2)} ₪'),
            if (record.refundBoxName.isNotEmpty)
              _info('صندوق الرد', record.refundBoxName),
            if (record.note.isNotEmpty) _info('ملاحظة', record.note),
            if (record.isCancelled) ...[
              _info('سبب الإلغاء', record.cancellationReason),
              if (record.replacementSalesReturnId > 0)
                _info('استُبدل بمرتجع رقم',
                    record.replacementSalesReturnId.toString()),
            ],
            if (record.replacesSalesReturnId > 0)
              _info(
                  'بديل عن مرتجع رقم', record.replacesSalesReturnId.toString()),
            if (record.sourceInvoices.isNotEmpty) ...[
              const Divider(height: 24),
              Text('فواتير البيع الأصلية',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 7.h),
              ...record.sourceInvoices.map(
                (invoice) => _SourceInvoiceCard(invoice: invoice),
              ),
            ],
            const Divider(height: 24),
            Text('المنتجات المرتجعة',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            ...record.items.map(
              (item) => _ReturnedProductCard(item: item),
            ),
            const Divider(height: 24),
            _AccountingSummary(record: record),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label)),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );

  Future<void> _cancelReturn(BuildContext context) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء فاتورة المرتجع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم عكس المخزون والرد النقدي ورصيد الطرف. لا يمكن الإلغاء إذا تم بيع مخزون المرتجع مرة أخرى.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reason,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (إلزامي)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().length < 3) return;
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء وعكس القيود'),
          ),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (confirmed != true || value.length < 3) return;
    final cancelled =
        await Get.find<SalesReturnsController>().cancelReturn(record.id, value);
    if (cancelled && context.mounted) Navigator.pop(context);
  }
}

class _SourceInvoiceCard extends StatelessWidget {
  const _SourceInvoiceCard({required this.invoice});

  final SalesReturnSourceInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading:
            const Icon(Icons.receipt_long_outlined, color: salesReturnColor),
        title: Text('${invoice.typeLabel} ${invoice.serial}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          'الكمية المباعة: ${invoice.soldQuantity} • سعر البيع: ${invoice.soldUnitPrice.toStringAsFixed(2)} ₪',
        ),
        trailing: IconButton(
          tooltip: 'فتح فاتورة البيع',
          onPressed: () => _openSaleInvoice(context, invoice),
          icon: const Icon(Icons.open_in_new_rounded, color: salesReturnColor),
        ),
      ),
    );
  }
}

class _ReturnedProductCard extends StatelessWidget {
  const _ReturnedProductCard({required this.item});

  final SalesReturnRecordItem item;

  @override
  Widget build(BuildContext context) {
    final variant = [item.sizeLabel, item.colorLabel]
        .where((value) => value.trim().isNotEmpty)
        .join(' / ');
    return Card(
      elevation: 0,
      color: salesReturnSurface,
      margin: EdgeInsets.only(bottom: 9.h),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9.r),
                  child: ProductPriorityImage(
                    imageUrls: item.productImages.isEmpty
                        ? [item.productImage]
                        : item.productImages,
                    width: 62.w,
                    height: 62.w,
                    fit: BoxFit.cover,
                    useThumbnail: true,
                    placeholder: Container(
                      width: 62.w,
                      height: 62.w,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
                    missingPlaceholder: Container(
                      width: 62.w,
                      height: 62.w,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      if (item.productCode.isNotEmpty)
                        Text('كود: ${item.productCode}',
                            style: TextStyle(
                                fontSize: 10.sp, color: Colors.grey.shade700)),
                      if (variant.isNotEmpty)
                        Text(variant, style: TextStyle(fontSize: 10.sp)),
                      SizedBox(height: 4.h),
                      Text(
                        '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ₪ = ${item.lineTotal.toStringAsFixed(2)} ₪',
                        style: const TextStyle(
                            color: salesReturnColor,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (item.saleInvoice != null)
                  IconButton(
                    tooltip: 'فتح فاتورة البيع',
                    onPressed: () =>
                        _openSaleInvoice(context, item.saleInvoice!),
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: salesReturnColor),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            if (item.saleInvoice != null)
              _smallInfo(
                'مصدر البيع',
                '${item.saleInvoice!.typeLabel} ${item.saleInvoice!.serial} • بيع ${item.saleInvoice!.soldQuantity} بسعر ${item.saleInvoice!.soldUnitPrice.toStringAsFixed(2)} ₪',
              ),
            _smallInfo(
              'تكلفة المخزون المعادة',
              '${item.inventoryTotalCost.toStringAsFixed(2)} ₪ (${item.inventoryUnitCost.toStringAsFixed(2)} ₪ للوحدة)',
            ),
            SizedBox(height: 5.h),
            Text('مصدر الشراء (تتبع FIFO)',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900)),
            if (item.purchaseSources.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 3.h),
                child: Text(
                  'لا يوجد تخصيص تكلفة تاريخي موثق لهذا البيع؛ لم يتم تخمين فاتورة شراء.',
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.orange.shade900),
                ),
              )
            else
              ...item.purchaseSources.map(
                (source) => Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: _smallInfo(
                    'فاتورة شراء #${source.billId}',
                    '${source.billDate.isEmpty ? '' : 'تاريخ ${source.billDate.split('T').first} • '}كمية الفاتورة ${source.invoiceQuantity.toStringAsFixed(0)} • المستلم ${source.receivedQuantity.toStringAsFixed(0)} • المخصص للبيع ${source.allocatedToSaleQuantity.toStringAsFixed(0)} • تكلفة ${source.unitCost.toStringAsFixed(2)} ${source.currency}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfo(String label, String value) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text('$label: $value', style: TextStyle(fontSize: 10.sp)),
      );
}

class _AccountingSummary extends StatelessWidget {
  const _AccountingSummary({required this.record});

  final SalesReturnRecord record;

  @override
  Widget build(BuildContext context) {
    final value = record.accounting;
    return Container(
      padding: EdgeInsets.all(11.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFD8CCF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('القيد المحاسبي للمرتجع',
              style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 6.h),
          Text('قيمة المرتجع: ${value.grossReturn.toStringAsFixed(2)} ₪'),
          Text('رد نقدي: ${value.cashRefund.toStringAsFixed(2)} ₪'),
          Text('رصيد للطرف: ${value.creditRefund.toStringAsFixed(2)} ₪'),
          Text(
              'تكلفة مخزون معادة: ${value.inventoryCostRestored.toStringAsFixed(2)} ₪'),
          Text('هامش معكوس: ${value.marginReversed.toStringAsFixed(2)} ₪'),
          if (value.refundBoxId > 0)
            Text('رقم صندوق الرد: ${value.refundBoxId}'),
          if (value.debtTransactionId > 0)
            Text('رقم حركة رصيد الطرف: ${value.debtTransactionId}'),
        ],
      ),
    );
  }
}

Future<void> _openSaleInvoice(
  BuildContext context,
  SalesReturnSourceInvoice invoice,
) async {
  Navigator.of(context).pop();
  if (invoice.isSalesOrder) {
    await Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: invoice.id);
    return;
  }
  if (!Get.isRegistered<SalesController>()) {
    Get.snackbar('تعذر فتح الفاتورة', 'متحكم المبيعات غير متاح حاليًا.');
    return;
  }
  await Get.find<SalesController>()
      .openInstantSaleBillDetails(invoice.id.toString());
}
