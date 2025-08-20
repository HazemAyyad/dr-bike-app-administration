// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../controllers/dashboard_controller.dart';
import 'stat_card.dart';

class BuildStatisticsCards extends GetView<DashboardController> {
  const BuildStatisticsCards({Key? key}) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
      ),
      child: Column(
        children: [
          // الصف الأول: ديون لنا وديون علينا
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'debtsForUs',
                  imageicon: AssetsManger.cashIcon,
                  value: controller.debtToUs.value.toString(),
                  subtitle: 'currency',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: StatCard(
                  title: 'debtsOnUs',
                  imageicon: AssetsManger.cashIcon,
                  value: controller.debtOnUs.value.toString(),
                  subtitle: 'currency',
                ),
              ),
            ],
          ),
          // الصف الثاني: المنتجات والموظفين
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'products',
                  imageicon: AssetsManger.productIcon,
                  value: controller.products.value.toString(),
                  subtitle: 'product',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: GetBuilder<DashboardController>(
                  builder: (_) {
                    return StatCard(
                      title: 'employees',
                      imageicon: AssetsManger.usersIcon,
                      value: controller.employeeService.employeeList.length
                          .toString(),
                      subtitle: 'employee',
                    );
                  },
                ),
              ),
            ],
          ),
          // SizedBox(height: 8.w),
          // الصف الثالث: مهام منجزة ومهام غير منجزة
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'completedTasks',
                  imageicon: AssetsManger.doneIcon,
                  value: controller.completedTasks.value.toString(),
                  subtitle: 'task',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: StatCard(
                  title: 'uncompletedTasks',
                  imageicon: AssetsManger.cancelIcon,
                  value: controller.pendingTasks.value.toString(),
                  subtitle: 'tasks',
                ),
              ),
            ],
          ),
          // SizedBox(height: 8.w),
          // الصف الرابع: مصاريف (عرض كامل)
          StatCard(
            title: 'expenses',
            imageicon: AssetsManger.moneyIcon,
            value: controller.expenses.value.toString(),
            subtitle: 'currency',
          ),
        ],
      ),
    );
  }
}
