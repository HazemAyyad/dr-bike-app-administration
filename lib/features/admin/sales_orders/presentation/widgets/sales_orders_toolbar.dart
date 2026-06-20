import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';



import '../../../../../core/services/theme_service.dart';

import '../../../../../core/utils/app_colors.dart';

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

                children: controller.statusTabs.map((status) {

                  final selected = active == status;

                  final color = SalesOrderStatusUi.statusColor(status);

                  return Padding(

                    padding: EdgeInsets.only(left: 8.w),

                    child: FilterChip(

                      label: Text(

                        controller.statusLabel(status),

                        style: TextStyle(

                          fontSize: 12.sp,

                          fontWeight:

                              selected ? FontWeight.w600 : FontWeight.normal,

                          color: selected

                              ? AppColors.primaryColor

                              : (ThemeService.isDark.value

                                  ? AppColors.whiteColor

                                  : Colors.grey.shade700),

                        ),

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

              child: Row(

                children: [

                  FilterChip(

                    label: Text('salesOrderBulkMode'.tr),

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

                    SizedBox(width: 8.w),

                    TextButton(

                      onPressed: controller.selectAllVisibleOrders,

                      child: Text('salesOrderBulkSelectAll'.tr),

                    ),

                    TextButton(

                      onPressed: controller.clearOrderSelection,

                      child: Text('salesOrderBulkClear'.tr),

                    ),

                    const Spacer(),

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

                            : () => controller.runBulkAction(action),

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

}

