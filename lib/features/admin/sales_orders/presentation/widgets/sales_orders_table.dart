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

/// عرض الطلبيات كبطاقات تشغيلية مضغوطة، بنفس لغة قسم الصيانة.
class SalesOrdersTable extends GetView<SalesOrdersController> {
  const SalesOrdersTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = controller.statusFilter.value == 'all'
          ? _groupOperationally(controller.orders)
          : _groupByDate(controller.orders);
      if (groups.isEmpty) return const SizedBox.shrink();
      final bulk =
          controller.bulkMode.value && controller.canBulkSelectCurrentTab;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups) ...[
            _DateHeader(
              label: group.label,
              count: group.orders.length,
              color: group.color,
              icon: group.icon,
              formatAsDate: group.formatAsDate,
            ),
            ...group.orders.map(
              (order) => _OrderCard(
                order: order,
                bulk: bulk,
                selected: controller.selectedOrderIds.contains(order.id),
                onSelect: (value) =>
                    controller.toggleOrderSelection(order.id, value),
                onTap: () {
                  if (bulk) {
                    controller.toggleOrderSelection(
                      order.id,
                      !controller.selectedOrderIds.contains(order.id),
                    );
                    return;
                  }
                  Get.toNamed(
                    AppRoutes.SALESORDERDETAILSCREEN,
                    arguments: order.id,
                  );
                },
                onLongPress: order.status == 'unconfirmed' && !bulk
                    ? () => controller.confirmOrder(order.id)
                    : null,
              ),
            ),
            SizedBox(height: 7.h),
          ],
        ],
      );
    });
  }

  List<_OrderGroup> _groupByDate(List<SalesOrderListItemModel> orders) {
    final grouped = <String, List<SalesOrderListItemModel>>{};
    for (final order in orders) {
      final raw = order.createdAt ?? '';
      final parsed = DateTime.tryParse(raw);
      final key = parsed == null
          ? (raw.length >= 10 ? raw.substring(0, 10) : '—')
          : DateFormat('yyyy-MM-dd').format(parsed);
      grouped.putIfAbsent(key, () => []).add(order);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((key) => _OrderGroup(
              key,
              grouped[key]!,
              color: AppColors.primaryColor,
              icon: Icons.calendar_today_outlined,
              formatAsDate: true,
            ))
        .toList();
  }

  List<_OrderGroup> _groupOperationally(
    List<SalesOrderListItemModel> orders,
  ) {
    const definitions = <_OperationalGroupDefinition>[
      _OperationalGroupDefinition(
          'طلبات جديدة', ['unconfirmed'], Colors.blue, Icons.fiber_new_rounded),
      _OperationalGroupDefinition('قيد التجهيز', ['confirmed', 'ready'],
          Colors.orange, Icons.inventory_2_outlined),
      _OperationalGroupDefinition('مع التوصيل', ['with_delivery'],
          Color(0xFFD97706), Icons.local_shipping_outlined),
      _OperationalGroupDefinition(
          'متابعة وإرجاع',
          [
            'review',
            'partial_delivered',
            'partial_return',
            'alternative_return',
            'returned',
            'stuck'
          ],
          Colors.deepPurple,
          Icons.sync_problem_outlined),
      _OperationalGroupDefinition('تم التسليم', ['delivered'], Colors.green,
          Icons.check_circle_outline_rounded),
      _OperationalGroupDefinition(
          'ملغاة', ['canceled'], Colors.red, Icons.cancel_outlined),
      _OperationalGroupDefinition(
          'مؤجلة سابقاً', ['postponed'], Colors.grey, Icons.schedule_outlined),
    ];
    return definitions
        .map((definition) {
          final rows = orders
              .where((order) => definition.statuses.contains(order.status))
              .toList();
          return _OrderGroup(
            definition.label,
            rows,
            color: definition.color,
            icon: definition.icon,
          );
        })
        .where((group) => group.orders.isNotEmpty)
        .toList();
  }
}

class _OperationalGroupDefinition {
  const _OperationalGroupDefinition(
    this.label,
    this.statuses,
    this.color,
    this.icon,
  );
  final String label;
  final List<String> statuses;
  final Color color;
  final IconData icon;
}

class _OrderGroup {
  const _OrderGroup(
    this.label,
    this.orders, {
    required this.color,
    required this.icon,
    this.formatAsDate = false,
  });
  final String label;
  final List<SalesOrderListItemModel> orders;
  final Color color;
  final IconData icon;
  final bool formatAsDate;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.formatAsDate,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool formatAsDate;

  @override
  Widget build(BuildContext context) {
    final date = formatAsDate ? DateTime.tryParse(label) : null;
    final text = !formatAsDate || date == null
        ? label
        : DateFormat('EEEE d MMMM', Get.locale?.languageCode ?? 'ar')
            .format(date);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 7.w),
          Icon(icon, size: 17.sp, color: color),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text('$count', style: TextStyle(fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.bulk,
    required this.selected,
    required this.onSelect,
    required this.onTap,
    this.onLongPress,
  });

  final SalesOrderListItemModel order;
  final bool bulk;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final statusColor = SalesOrderStatusUi.statusColor(order.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.08)
                : dark
                    ? AppColors.customGreyColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (bulk)
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelect(value ?? false),
                  visualDensity: VisualDensity.compact,
                )
              else
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: statusColor,
                    size: 19.sp,
                  ),
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customerName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          order.serialNumber ?? '#${order.id}',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _Meta(
                          icon: Icons.location_on_outlined,
                          text: order.cityName ?? '—',
                        ),
                        SizedBox(width: 8.w),
                        _Meta(
                          icon: Icons.payments_outlined,
                          text: '${order.total.toStringAsFixed(2)} ₪',
                          strong: true,
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            Get.find<SalesOrdersController>()
                                .statusLabel(order.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining_outlined,
                          size: 13.sp,
                          color: statusColor,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'وسيلة التوصيل: ${_deliveryLabel(order)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: SalesOrdersController.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.chevron_left_rounded, size: 19.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _deliveryLabel(SalesOrderListItemModel order) {
    final name = order.deliveryCompanyName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (order.status == 'unconfirmed' ||
        order.status == 'confirmed' ||
        order.status == 'ready' ||
        order.status == 'postponed') {
      return 'لم تُحدد بعد';
    }
    return 'غير مسجلة';
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.strong = false});
  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: Colors.grey.shade600),
        SizedBox(width: 2.w),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            color: strong ? AppColors.primaryColor : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
