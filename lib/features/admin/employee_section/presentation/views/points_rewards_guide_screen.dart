import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../data/models/employee_reward_rule_model.dart';
import '../controllers/employee_point_categories_controller.dart';
import '../controllers/employee_reward_rules_controller.dart';

/// Read-only "guide" screen that shows admins (and can be reused for any
/// authorised role) what each behaviour is worth and how monthly net
/// points convert into a monetary reward. All data is fetched live from
/// the existing controllers — no static configuration is hardcoded here.
class PointsRewardsGuideScreen extends StatelessWidget {
  const PointsRewardsGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    final categoriesController = Get.find<EmployeePointCategoriesController>();
    final rulesController = Get.find<EmployeeRewardRulesController>();

    Future<void> refresh() async {
      await Future.wait([
        categoriesController.loadCategories(),
        rulesController.loadRules(),
      ]);
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'pointsGuideTitle',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'pointsGuideRefresh'.tr,
            icon: Icon(
              Icons.refresh_rounded,
              size: 24.sp,
              color: isDark
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
            onPressed: refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Obx(() {
          final loading = categoriesController.isLoading.value ||
              rulesController.isLoading.value;
          final positives = categoriesController.positiveCategories
              .where((c) => c.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final negatives = categoriesController.negativeCategories
              .where((c) => c.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final rules = rulesController.rules
              .where((r) => r.isActive)
              .toList()
            ..sort((a, b) => a.minPoints.compareTo(b.minPoints));

          if (loading &&
              positives.isEmpty &&
              negatives.isEmpty &&
              rules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (positives.isEmpty && negatives.isEmpty && rules.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 120.h),
                Icon(
                  Icons.redeem_outlined,
                  size: 56.sp,
                  color: AppColors.primaryColor,
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    'pointsGuideEmpty'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            children: [
              _Section(
                title: 'pointsGuidePositive'.tr,
                icon: Icons.trending_up_rounded,
                accent: const Color(0xFF16A34A),
                isDark: isDark,
                child: positives.isEmpty
                    ? _EmptyHint(
                        label: 'pointsGuideCategoriesEmpty'.tr,
                        isDark: isDark,
                      )
                    : Column(
                        children: positives
                            .map(
                              (c) => _CategoryTile(
                                category: c,
                                isDark: isDark,
                                accent: const Color(0xFF16A34A),
                              ),
                            )
                            .toList(),
                      ),
              ),
              SizedBox(height: 12.h),
              _Section(
                title: 'pointsGuideNegative'.tr,
                icon: Icons.trending_down_rounded,
                accent: const Color(0xFFDC2626),
                isDark: isDark,
                child: negatives.isEmpty
                    ? _EmptyHint(
                        label: 'pointsGuideCategoriesEmpty'.tr,
                        isDark: isDark,
                      )
                    : Column(
                        children: negatives
                            .map(
                              (c) => _CategoryTile(
                                category: c,
                                isDark: isDark,
                                accent: const Color(0xFFDC2626),
                              ),
                            )
                            .toList(),
                      ),
              ),
              SizedBox(height: 12.h),
              _Section(
                title: 'pointsGuideRewards'.tr,
                icon: Icons.emoji_events_rounded,
                accent: const Color(0xFFB45309),
                isDark: isDark,
                child: rules.isEmpty
                    ? _EmptyHint(
                        label: 'pointsGuideRewardsEmpty'.tr,
                        isDark: isDark,
                      )
                    : Column(
                        children: rules
                            .map((r) => _RewardTile(
                                  rule: r,
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
              ),
              SizedBox(height: 30.h),
            ],
          );
        }),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F23) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, size: 18.sp, color: accent),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isDark,
    required this.accent,
  });

  final EmployeePointCategoryModel category;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final name = isArabic
        ? (category.nameAr.isNotEmpty
            ? category.nameAr
            : category.nameEn ?? category.code)
        : (category.nameEn != null && category.nameEn!.isNotEmpty
            ? category.nameEn!
            : category.nameAr.isNotEmpty
                ? category.nameAr
                : category.code);
    final sign = category.isAdd ? '+' : '-';
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  category.code,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$sign${category.defaultPoints}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.rule, required this.isDark});

  final EmployeeRewardRuleModel rule;
  final bool isDark;

  Color _resolveColor() {
    final s = rule.statusColor?.trim();
    if (s == null || s.isEmpty) return const Color(0xFF9CA3AF);
    var str = s.startsWith('#') ? s.substring(1) : s;
    if (str.length == 6) str = 'FF$str';
    if (str.length != 8) return const Color(0xFF9CA3AF);
    final v = int.tryParse(str, radix: 16);
    if (v == null) return const Color(0xFF9CA3AF);
    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final rangeText = rule.maxPoints == null
        ? '${rule.minPoints} ${'pointsGuideOpenEnded'.tr}'
        : '${rule.minPoints} – ${rule.maxPoints}';
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rule.statusLabel != null &&
                    rule.statusLabel!.trim().isNotEmpty)
                  Text(
                    rule.statusLabel!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                SizedBox(height: 2.h),
                Text(
                  '${'pointsGuideRange'.tr}: $rangeText',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${rule.rewardAmount} ${'currency'.tr}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              Text(
                'pointsGuideReward'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark
                      ? Colors.white54
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
