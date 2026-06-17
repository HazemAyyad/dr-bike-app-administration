import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import 'sales_order_status_ui.dart';

/// جدول الطلبيات — نفس أسلوب جدول المبيعات الفورية.
class SalesOrdersTable extends GetView<SalesOrdersController> {
  const SalesOrdersTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = _groupOrdersByDate(controller.orders);
      if (groups.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OrdersTableHeader(),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) SizedBox(height: 14.h),
            _DateGroupHeader(label: groups[i].label),
            ...groups[i].orders.map(
              (order) => _OrderTableRow(
                order: order,
                statusLabel: controller.statusLabel(order.status),
                onTap: () => Get.toNamed(
                  AppRoutes.SALESORDERDETAILSCREEN,
                  arguments: order.id,
                ),
                onConfirm: order.status == 'unconfirmed'
                    ? () => controller.confirmOrder(order.id)
                    : null,
              ),
            ),
          ],
          SizedBox(height: 4.h),
        ],
      );
    });
  }

  List<_OrderDateGroup> _groupOrdersByDate(List<SalesOrderListItemModel> orders) {
    final map = <String, List<SalesOrderListItemModel>>{};
    for (final order in orders) {
      final key = _dateKey(order.createdAt);
      map.putIfAbsent(key, () => []).add(order);
    }
    final keys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return keys.map((key) {
      return _OrderDateGroup(
        label: _formatDateHeader(key, map[key]!.length),
        orders: map[key]!,
      );
    }).toList();
  }

  String _dateKey(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(raw));
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _formatDateHeader(String key, int count) {
    if (key == '—') {
      return '${'salesOrders'.tr} ($count)';
    }
    try {
      final dt = DateTime.parse(key);
      final day = DateFormat('EEEE d MMMM yyyy', Get.locale?.languageCode ?? 'ar')
          .format(dt);
      return '$day ($count)';
    } catch (_) {
      return '$key ($count)';
    }
  }
}

class _OrderDateGroup {
  const _OrderDateGroup({required this.label, required this.orders});

  final String label;
  final List<SalesOrderListItemModel> orders;
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = ThemeService.isDark.value
        ? AppColors.primaryColor.withValues(alpha: 0.15)
        : AppColors.primaryColor.withValues(alpha: 0.08);

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
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _OrdersTableHeader extends StatelessWidget {
  const _OrdersTableHeader();

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
      child: Row(
        children: const [
          _HeaderCell('salesOrderNumber', flex: 2),
          _HeaderCell('customer', flex: 2),
          _HeaderCell('total', flex: 2),
          _HeaderCell('status', flex: 2),
          _HeaderCell('orderDate', flex: 2),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.labelKey, {required this.flex});

  final String labelKey;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        labelKey.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({
    required this.order,
    required this.statusLabel,
    required this.onTap,
    this.onConfirm,
  });

  final SalesOrderListItemModel order;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final statusColor = SalesOrderStatusUi.statusColor(order.status);
    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;
    final cancelled = order.status == 'canceled';

    return Material(
      color: cancelled ? Colors.red.withValues(alpha: 0.06) : bg,
      child: InkWell(
        onTap: onTap,
        onLongPress: onConfirm,
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
                child: Text(
                  order.serialNumber ?? '#${order.id}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.customerName ?? '—',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    if (order.cityName != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        order.cityName!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${order.total.toStringAsFixed(2)} ₪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: cancelled ? Colors.red.shade700 : null,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(order.createdAt),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
