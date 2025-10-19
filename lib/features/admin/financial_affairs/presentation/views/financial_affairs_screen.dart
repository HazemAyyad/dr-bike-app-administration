import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../buying/presentation/views/buying_screen.dart';

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
                MainPageWidget(
                  onTap: () {
                    Get.toNamed(AppRoutes.ASSETSSCREEN);
                  },
                  icon: AssetsManager.solarIcon,
                  title: 'assets'.tr,
                ),
                MainPageWidget(
                  onTap: () {
                    Get.toNamed(AppRoutes.THEEXPENSESSCREEN);
                  },
                  icon: AssetsManager.cashIcon,
                  title: 'theExpenses'.tr,
                ),
                MainPageWidget(
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
