import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../sales/presentation/views/delivery_company_accounts_screen.dart';

import '../controllers/sales_orders_controller.dart';

import 'sales_order_status_ui.dart';

/// شريط فلتر الحالة + الإجراءات الجماعية.

class SalesOrdersToolbar extends GetView<SalesOrdersController> {
  const SalesOrdersToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final active = controller.statusFilter.value;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.visibleStatusTabs.map((status) {
                  final selected = active == status;

                  final color = SalesOrderStatusUi.statusColor(status);

                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.statusLabel(status),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.primaryColor
                                  : (ThemeService.isDark.value
                                      ? AppColors.whiteColor
                                      : Colors.grey.shade700),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(99.r),
                            ),
                            child: Text(
                              '${controller.statusCounts[status] ?? 0}',
                              style: TextStyle(
                                color: color,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) => controller.changeStatusFilter(status),
                      backgroundColor: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      selectedColor: color.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primaryColor,
                      side: BorderSide(
                        color: selected ? color : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          Obx(() {
            if (!controller.canBulkSelectCurrentTab) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(
                      controller.statusFilter.value == 'unconfirmed'
                          ? 'تحديد عدة طلبيات للتأكيد'
                          : controller.statusFilter.value == 'confirmed'
                              ? 'تحديد عدة طلبيات للتجهيز'
                              : 'تحديد عدة طلبيات للتسوية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: controller.bulkMode.value,
                    onSelected: controller.toggleBulkMode,
                    avatar: Icon(
                      controller.bulkMode.value
                          ? Icons.checklist_rtl
                          : Icons.checklist_outlined,
                      size: 18.sp,
                    ),
                  ),
                  if (controller.bulkMode.value) ...[
                    TextButton(
                      onPressed: controller.selectAllVisibleOrders,
                      child: Text('salesOrderBulkSelectAll'.tr),
                    ),
                    TextButton(
                      onPressed: controller.clearOrderSelection,
                      child: Text('salesOrderBulkClear'.tr),
                    ),
                    Text(
                      'salesOrderBulkSelected'.trParams({
                        'count': '${controller.selectedOrderIds.length}',
                      }),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: SalesOrdersController.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          Obx(() {
            if (!controller.bulkMode.value ||
                controller.selectedOrderIds.isEmpty ||
                controller.bulkActionsForCurrentTab.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.bulkActionsForCurrentTab.map((action) {
                    final isDanger = action == 'cancel';

                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => action == 'settle'
                                ? _settleSelected(context)
                                : controller.runBulkAction(action),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDanger
                              ? const Color(0xFFDC2626)
                              : SalesOrdersController.textPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                        ),
                        child: Text(controller.bulkActionLabel(action)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _settleSelected(BuildContext context) async {
    final chosen = controller.orders
        .where((order) => controller.selectedOrderIds.contains(order.id))
        .toList();
    if (chosen.isEmpty) return;
    final eligible = chosen
        .where((order) =>
            order.carrierReceivableBalance > 0 &&
            order.deliveryCompanyId != null &&
            (order.deliveryCompanyName ?? '').trim().isNotEmpty)
        .toList();
    if (eligible.isEmpty) {
      Get.snackbar(
        'لا توجد مستحقات شركات توصيل',
        'التسوية الجماعية مخصصة لمستحقات شركة التوصيل. ديون الزبائن تتم تسويتها من الطلبية.',
      );
      return;
    }
    final grouped = <int, _SettlementCompanyGroup>{};
    for (final order in eligible) {
      final companyId = order.deliveryCompanyId!;
      final companyName = order.deliveryCompanyName!.trim();
      final group = grouped.putIfAbsent(
        companyId,
        () => _SettlementCompanyGroup(companyId, companyName),
      );
      group.orders.add({
        'id': order.id,
        'serial_number': order.serialNumber,
        'customer_name': order.customerName,
        'carrier_receivable_balance': order.carrierReceivableBalance,
      });
    }
    final selectedGroups = await showDialog<List<_SettlementCompanyGroup>>(
      context: context,
      builder: (_) => _SettlementCompaniesDialog(
        groups: grouped.values.toList(),
        excludedCount: chosen.length - eligible.length,
      ),
    );
    if (selectedGroups == null || selectedGroups.isEmpty) return;

    var completed = 0;
    for (final group in selectedGroups) {
      final done = await Get.dialog<bool>(
        BatchSettlementDialog(
          companyId: group.companyId,
          companyName: group.companyName,
          orders: group.orders,
          api: Get.find<DioConsumer>(),
        ),
        barrierDismissible: false,
      );
      if (done != true) break;
      completed++;
    }
    if (completed > 0) {
      controller.toggleBulkMode(false);
      await controller.loadOrders();
      if (completed == selectedGroups.length && completed > 1) {
        Get.snackbar('اكتملت التسويات', 'تمت تسوية $completed شركات بنجاح');
      }
    }
  }
}

class _SettlementCompanyGroup {
  _SettlementCompanyGroup(this.companyId, this.companyName);
  final int companyId;
  final String companyName;
  final List<Map<String, dynamic>> orders = [];

  double get total => orders.fold<double>(
        0,
        (sum, order) =>
            sum +
            ((order['carrier_receivable_balance'] as num?) ?? 0).toDouble(),
      );
}

class _SettlementCompaniesDialog extends StatefulWidget {
  const _SettlementCompaniesDialog({
    required this.groups,
    required this.excludedCount,
  });
  final List<_SettlementCompanyGroup> groups;
  final int excludedCount;

  @override
  State<_SettlementCompaniesDialog> createState() =>
      _SettlementCompaniesDialogState();
}

class _SettlementCompaniesDialogState
    extends State<_SettlementCompaniesDialog> {
  final Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    selectedIds.addAll(widget.groups.map((group) => group.companyId));
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroups = widget.groups
        .where((group) => selectedIds.contains(group.companyId))
        .toList();
    final selectedTotal =
        selectedGroups.fold<double>(0, (sum, group) => sum + group.total);
    return AlertDialog(
      title: const Text('ملخص التسوية حسب الشركات'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${selectedGroups.length} شركات • ${selectedTotal.toStringAsFixed(2)} ₪',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (widget.excludedCount > 0)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '${widget.excludedCount} طلبيات تحتوي دين زبون أو لا توجد لها شركة توصيل، ولن تدخل في هذه التسوية.',
                  style: const TextStyle(color: Color(0xFFB45309)),
                ),
              ),
            SizedBox(height: 8.h),
            for (final group in widget.groups)
              CheckboxListTile(
                value: selectedIds.contains(group.companyId),
                onChanged: (value) => setState(() {
                  value == true
                      ? selectedIds.add(group.companyId)
                      : selectedIds.remove(group.companyId);
                }),
                title: Text(group.companyName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${group.orders.length} طلبيات'),
                secondary: Text('${group.total.toStringAsFixed(2)} ₪',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: selectedGroups.isEmpty
              ? null
              : () => Get.back(result: selectedGroups),
          child: const Text('متابعة التسوية'),
        ),
      ],
    );
  }
}
