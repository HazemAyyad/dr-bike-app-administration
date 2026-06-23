import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/daily_session_model.dart';
import '../binding/sales_binding.dart';
import '../controllers/sales_controller.dart';
class SalesDailySessionSalesLog extends StatelessWidget {
  const SalesDailySessionSalesLog({
    Key? key,
    required this.instantSales,
    required this.profitSales,
  }) : super(key: key);

  final List<DailySessionSaleLogRow> instantSales;
  final List<DailySessionSaleLogRow> profitSales;

  @override
  Widget build(BuildContext context) {
    if (instantSales.isEmpty && profitSales.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text('noData'.tr, style: TextStyle(fontSize: 12.sp)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: '${'instant_sales'.tr} (${instantSales.length})'),
              Tab(text: '${'cashProfit'.tr} (${profitSales.length})'),
            ],
          ),
          SizedBox(
            height: 320.h,
            child: TabBarView(
              children: [
                _SalesList(
                  items: instantSales,
                  emptyLabel: 'noData'.tr,
                ),
                _SalesList(
                  items: profitSales,
                  emptyLabel: 'noData'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  const _SalesList({
    required this.items,
    required this.emptyLabel,
  });

  final List<DailySessionSaleLogRow> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyLabel, style: TextStyle(fontSize: 12.sp)));
    }

    return ListView.separated(
      padding: EdgeInsets.only(top: 8.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 6.h),
      itemBuilder: (context, index) => _SaleRow(
        sale: items[index],
        onTap: () => _onSaleTap(context, items[index]),
      ),
    );
  }

  Future<void> _onSaleTap(BuildContext context, DailySessionSaleLogRow sale) async {
    if (sale.isSalesOrderDelivery && sale.salesOrderId != null) {
      await Get.toNamed(
        AppRoutes.SALESORDERDETAILSCREEN,
        arguments: sale.salesOrderId,
      );
      return;
    }

    if (sale.isInstant) {
      _ensureSalesController();
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().openInstantSaleBillDetails(
          sale.id.toString(),
        );
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'cashProfit'.tr} #${sale.id}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            if (sale.buyerName?.isNotEmpty ?? false)
              Text('${'buyerName'.tr}: ${sale.buyerName}'),
            Text('${'totalCost'.tr}: ${sale.totalCost.toStringAsFixed(2)}'),
            if (sale.paymentBoxName?.isNotEmpty ?? false)
              Text('${'boxName'.tr}: ${sale.paymentBoxName}'),
            if (sale.notes?.isNotEmpty ?? false) ...[
              SizedBox(height: 6.h),
              Text(sale.notes!),
            ],
            if (sale.createdAt != null) ...[
              SizedBox(height: 6.h),
              Text(sale.createdAt!, style: TextStyle(fontSize: 11.sp)),
            ],
          ],
        ),
      ),
    );
  }

  void _ensureSalesController() {
    AppDependencyRegistry.ensureSales();
    if (!Get.isRegistered<SalesController>()) {
      SalesBinding().dependencies();
    }
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.sale,
    required this.onTap,
  });

  final DailySessionSaleLogRow sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelled = sale.isCancelled;
    final typeLabel = sale.isSalesOrderDelivery
        ? 'salesOrders'.tr
        : sale.isInstant
            ? 'instantSale'.tr
            : 'cashProfit'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: cancelled
                  ? Colors.red.shade200
                  : Colors.grey.shade300,
            ),
            color: cancelled
                ? Colors.red.withValues(alpha: 0.04)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sale.isSalesOrderDelivery
                              ? (sale.salesOrderSerial ?? '#${sale.salesOrderId ?? sale.id}')
                              : '#${sale.id}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (sale.isFromSalesOrder) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'salesOrders'.tr,
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (cancelled) ...[
                          SizedBox(width: 6.w),
                          Text(
                            'cancelled'.tr,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      sale.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        decoration:
                            cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (sale.buyerName?.isNotEmpty ?? false) ...[
                      SizedBox(height: 2.h),
                      Text(
                        sale.buyerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (sale.createdAt != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        _shortTime(sale.createdAt!),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sale.totalCost.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: cancelled ? Colors.red.shade700 : null,
                    ),
                  ),
                  if (sale.isInstant && sale.quantity > 0)
                    Text(
                      'x${sale.quantity.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  if (sale.paidAmount > 0 && sale.remainingAmount > 0.01)
                    Text(
                      '${'paidAmount'.tr}: ${sale.paidAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 9.sp, color: Colors.green),
                    ),
                ],
              ),
              SizedBox(width: 4.w),
              Icon(Icons.chevron_left, size: 18.sp, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  String _shortTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final locale = Get.locale?.languageCode ?? 'ar';
      return DateFormat('d/M/yyyy hh:mm a', locale).format(dt);
    } catch (_) {
      if (raw.length >= 16) return raw.substring(0, 16);
      return raw;
    }
  }
}
