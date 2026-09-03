import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../routes/app_routes.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
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
      return Column(
        children: rows
            .map((row) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _SalesReturnCard(record: row),
                ))
            .toList(),
      );
    });
  }
}

class _SalesReturnCard extends StatelessWidget {
  const _SalesReturnCard({required this.record});

  final SalesReturnRecord record;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: salesReturnSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _showDetails(context),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFF4C7C3)),
          ),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 54.h,
                margin: EdgeInsetsDirectional.only(end: 9.w),
                decoration: BoxDecoration(
                  color: salesReturnColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              CircleAvatar(
                backgroundColor: salesReturnColor.withValues(alpha: .11),
                child: const Icon(Icons.assignment_return_outlined,
                    color: salesReturnColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.serialNumber,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: salesReturnColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: salesReturnColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                              record.isCancelled
                                  ? 'مرتجع ملغى'
                                  : 'مرتجع مبيعات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '${record.isSeller ? 'مورد / تاجر' : 'زبون'}: ${record.partnerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${record.returnedQuantity} قطعة • ${record.itemsCount} صنف • ${_date(record.completedAt)}',
                      style: TextStyle(
                          fontSize: 10.sp, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  Text(
                    '${record.totalAmount.toStringAsFixed(2)} ₪',
                    style: TextStyle(
                      color: salesReturnColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded,
                      color: salesReturnColor),
                ],
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
    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }
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
