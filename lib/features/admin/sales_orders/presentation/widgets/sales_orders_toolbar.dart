import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_orders_controller.dart';
import 'sales_order_status_ui.dart';

/// شريط فلتر الحالة — بنفس أسلوب شريط بحث المبيعات الفورية.
class SalesOrdersToolbar extends GetView<SalesOrdersController> {
  const SalesOrdersToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Obx(() {
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
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
    );
  }
}
