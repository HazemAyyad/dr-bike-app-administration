import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/sales_return_models.dart';
import '../controllers/sales_returns_controller.dart';

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
                          child: Text('مرتجع مبيعات',
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
                  child: Text(record.serialNumber,
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w900)),
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
            const Divider(height: 24),
            Text('المنتجات المرتجعة',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            ...record.items.map(
              (item) => Card(
                elevation: 0,
                color: salesReturnSurface,
                child: ListTile(
                  title: Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ₪',
                  ),
                  trailing: Text('${item.lineTotal.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                          color: salesReturnColor,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ),
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
}
