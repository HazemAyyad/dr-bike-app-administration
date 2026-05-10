import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    final items = <_SettingsItem>[
      _SettingsItem(
        icon: Icons.emoji_events_outlined,
        iconColor: const Color(0xFFB45309),
        titleKey: 'rewardRulesSetting',
        descriptionKey: 'rewardRulesSettingDesc',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEREWARDRULESSCREEN),
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'generalSettings',
        action: false,
        backgroundColor: pageBg,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemBuilder: (_, i) => _SettingsCard(item: items[i], isDark: isDark),
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemCount: items.length,
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descriptionKey,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descriptionKey;
  final VoidCallback onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.item, required this.isDark});

  final _SettingsItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.customGreyColor : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final descColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final chevronColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: item.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleKey.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.descriptionKey.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: chevronColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
