import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class EmployeePointsSettingsScreen extends StatelessWidget {
  const EmployeePointsSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);
    final items = [
      _PointSettingsItem(
        icon: Icons.rule_rounded,
        color: const Color(0xFF7C3AED),
        title: 'قواعد النقاط التلقائية',
        subtitle: 'إضافة قواعد يومية وأسبوعية وشهرية للنقاط',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEPOINTRULESSCREEN),
      ),
      _PointSettingsItem(
        icon: Icons.tune_rounded,
        color: const Color(0xFF2563EB),
        title: 'pointCategoriesSetting'.tr,
        subtitle: 'pointCategoriesSettingDesc'.tr,
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEPOINTCATEGORIESSCREEN),
      ),
      _PointSettingsItem(
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFB45309),
        title: 'rewardRulesSetting'.tr,
        subtitle: 'rewardRulesSettingDesc'.tr,
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEREWARDRULESSCREEN),
      ),
      _PointSettingsItem(
        icon: Icons.query_stats_rounded,
        color: const Color(0xFF0F766E),
        title: 'pointsReportTitle'.tr,
        subtitle: 'تقرير إجمالي النقاط والخصومات والمكافآت حسب الفترة',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEPOINTSREPORTSCREEN),
      ),
      _PointSettingsItem(
        icon: Icons.stars_rounded,
        color: const Color(0xFFEA580C),
        title: 'subtaskBonusDefaultSetting'.tr,
        subtitle: 'subtaskBonusDefaultSettingDesc'.tr,
        onTap: () => _editSubtaskBonusDefault(context),
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'إعدادات النقاط',
        action: false,
        backgroundColor: pageBg,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, i) => _PointSettingsCard(item: items[i]),
      ),
    );
  }

  Future<void> _editSubtaskBonusDefault(BuildContext context) async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    if (!context.mounted) return;
    final initial = AppSettingsService.instance.subtaskBonusDefault.value;
    final ctrl = TextEditingController(text: '$initial');

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const actionBg = Color(0xFFE5E7EB);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'subtaskBonusDefaultSetting'.tr,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'bonusPointsValue'.tr,
            labelStyle: const TextStyle(color: textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: actionBg,
              foregroundColor: textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    if (saved != true) {
      ctrl.dispose();
      return;
    }

    final value = int.tryParse(ctrl.text.trim()) ?? initial;
    ctrl.dispose();
    if (value < 0) return;

    final ok =
        await AppSettingsService.instance.updateSubtaskBonusDefault(value);
    if (!context.mounted) return;
    if (ok) {
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: 'settingsUpdated'.tr,
      );
    } else {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'settingsUpdateFailed'.tr,
      );
    }
  }
}

class _PointSettingsItem {
  const _PointSettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _PointSettingsCard extends StatelessWidget {
  const _PointSettingsCard({required this.item});

  final _PointSettingsItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Material(
      color: isDark ? const Color(0xFF1F1F23) : Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(item.icon, color: item.color, size: 23.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_left_rounded,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
