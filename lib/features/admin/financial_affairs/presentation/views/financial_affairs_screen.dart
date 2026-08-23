import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';

class FinancialAffairsScreen extends StatelessWidget {
  const FinancialAffairsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'financialMatters', action: false),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9.r),
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
            ),
            child: Column(
              children: [
                _FinancialTile(
                  onTap: () {
                    Get.toNamed(AppRoutes.ASSETSSCREEN);
                  },
                  icon: AssetsManager.solarIcon,
                  title: 'assets'.tr,
                ),
                _FinancialTile(
                  onTap: () {
                    Get.toNamed(AppRoutes.THEEXPENSESSCREEN);
                  },
                  icon: AssetsManager.cashIcon,
                  title: 'theExpenses'.tr,
                ),
                _FinancialTile(
                  onTap: () {
                    Get.toNamed(AppRoutes.OFFICIALPAPERSSCREEN);
                  },
                  icon: AssetsManager.mingcuteIcon,
                  title: 'officialPapers'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialTile extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;
  final String title;

  const _FinancialTile({
    required this.onTap,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        child: Row(
          children: [
            Image.asset(icon, width: 28.w, height: 28.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.primaryColor,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}
