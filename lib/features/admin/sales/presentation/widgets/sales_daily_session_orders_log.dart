import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/daily_session_model.dart';
import '../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../sales_orders/presentation/widgets/sales_order_status_ui.dart';

class SalesDailySessionOrdersLog extends StatelessWidget {
  const SalesDailySessionOrdersLog({
    Key? key,
    required this.orders,
  }) : super(key: key);

  final List<DailySessionOrderLogRow> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'salesDailyNoOrdersToday'.tr,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => SizedBox(height: 6.h),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.toNamed(
              AppRoutes.SALESORDERDETAILSCREEN,
              arguments: order.id,
            ),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
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
                              order.serialNumber ?? '#${order.id}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            if (order.deliveredToday) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'salesOrderDeliveredToday'.tr,
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (order.customerName?.isNotEmpty ?? false) ...[
                          SizedBox(height: 2.h),
                          Text(
                            order.customerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: SalesOrderStatusUi.statusColor(order.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: SalesOrderStatusUi.statusColor(order.status)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            _statusLabel(order.status),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: SalesOrderStatusUi.statusColor(order.status),
                            ),
                          ),
                        ),
                        if (order.createdAt?.isNotEmpty ?? false) ...[
                          SizedBox(height: 4.h),
                          Text(
                            _formatDateTime(order.createdAt!),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${order.total.toStringAsFixed(0)} ₪',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(Icons.chevron_left, size: 18.sp, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    if (Get.isRegistered<SalesOrdersController>()) {
      return Get.find<SalesOrdersController>().statusLabel(status);
    }
    return status;
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final locale = Get.locale?.languageCode ?? 'ar';
      return DateFormat('d/M/yyyy hh:mm a', locale).format(dt);
    } catch (_) {
      return raw;
    }
  }
}
