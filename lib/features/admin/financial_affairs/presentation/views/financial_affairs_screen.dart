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
    final isDark = ThemeService.isDark.value;
    final sections = [
      _FinancialSection(
        title: 'theExpenses'.tr,
        subtitle: 'المصاريف العمومية والرواتب وإتلاف البضاعة والتقارير',
        iconAsset: AssetsManager.cashIcon,
        color: AppColors.operationalPurple,
        onTap: () => Get.toNamed(AppRoutes.THEEXPENSESSCREEN),
      ),
      _FinancialSection(
        title: 'assets'.tr,
        subtitle: 'الأصول والقيمة الدفترية والإهلاك الشهري التلقائي',
        iconAsset: AssetsManager.solarIcon,
        color: AppColors.customGreen1,
        onTap: () => Get.toNamed(AppRoutes.ASSETSSCREEN),
      ),
      _FinancialSection(
        title: 'officialPapers'.tr,
        subtitle: 'الخزن والملفات والأوراق والصور الرسمية المؤرشفة',
        iconAsset: AssetsManager.mingcuteIcon,
        color: AppColors.primaryColor,
        onTap: () => Get.toNamed(AppRoutes.OFFICIALPAPERSSCREEN),
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'financialMatters', action: false),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.customGreyColor
                  : AppColors.operationalNavy,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.operationalNavy.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مركز الشؤون المالية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'إدارة القيود والتقارير والمستندات من مكان واحد',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 11.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'الأقسام',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 8.h),
          ...sections.map((section) => _FinancialSectionCard(section: section)),
        ],
      ),
    );
  }
}

class _FinancialSection {
  const _FinancialSection({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;
}

class _FinancialSectionCard extends StatelessWidget {
  const _FinancialSectionCard({required this.section});

  final _FinancialSection section;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: section.onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.04),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Image.asset(section.iconAsset),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : AppColors.operationalNavy,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      section.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        height: 1.35,
                        color: AppColors.customGreyColor5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: section.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
