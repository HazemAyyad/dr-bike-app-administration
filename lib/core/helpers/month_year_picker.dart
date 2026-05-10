import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

/// Shared month/year picker used by the points + reports admin screens.
/// Opens a clean bottom sheet with the current selection highlighted.
class MonthYearPicker {
  MonthYearPicker._();

  static const List<String> _monthKeys = <String>[
    'month_january',
    'month_february',
    'month_march',
    'month_april',
    'month_may',
    'month_june',
    'month_july',
    'month_august',
    'month_september',
    'month_october',
    'month_november',
    'month_december',
  ];

  static String monthLabel(int month) {
    final i = (month - 1).clamp(0, 11);
    final key = _monthKeys[i];
    final translated = key.tr;
    if (translated == key) {
      // Fallback when translation is missing.
      return '${'month'.tr} $month';
    }
    return translated;
  }

  static Future<int?> pickMonth(
    BuildContext context, {
    required int selected,
  }) {
    final isDark = ThemeService.isDark.value;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _PickerSheet(
          title: 'pickMonth'.tr,
          isDark: isDark,
          itemCount: 12,
          itemBuilder: (i) {
            final month = i + 1;
            return _PickerTile(
              label: monthLabel(month),
              trailing: month.toString().padLeft(2, '0'),
              selected: month == selected,
              isDark: isDark,
              onTap: () => Navigator.of(ctx).pop(month),
            );
          },
        );
      },
    );
  }

  static Future<int?> pickYear(
    BuildContext context, {
    required int selected,
    int yearsBack = 3,
    int yearsForward = 2,
  }) {
    final isDark = ThemeService.isDark.value;
    final currentYear = DateTime.now().year;
    final start = currentYear - yearsBack;
    final total = yearsBack + yearsForward + 1;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _PickerSheet(
          title: 'pickYear'.tr,
          isDark: isDark,
          itemCount: total,
          itemBuilder: (i) {
            final year = start + i;
            return _PickerTile(
              label: year.toString(),
              trailing: year == currentYear ? 'thisYear'.tr : null,
              selected: year == selected,
              isDark: isDark,
              onTap: () => Navigator.of(ctx).pop(year),
            );
          },
        );
      },
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.isDark,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final bool isDark;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1.h,
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: itemCount,
                separatorBuilder: (_, __) => SizedBox(height: 2.h),
                itemBuilder: (_, i) => itemBuilder(i),
              ),
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final selectedBg = (isDark
            ? AppColors.primaryColor
            : AppColors.secondaryColor)
        .withValues(alpha: 0.12);
    final selectedFg =
        isDark ? AppColors.primaryColor : AppColors.secondaryColor;
    final defaultFg =
        isDark ? Colors.white : const Color(0xFF111827);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: selected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? selectedFg : defaultFg,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? selectedFg
                          : (isDark
                              ? Colors.white54
                              : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20.sp,
                  color: selected
                      ? selectedFg
                      : (isDark
                          ? Colors.white24
                          : const Color(0xFFD1D5DB)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
