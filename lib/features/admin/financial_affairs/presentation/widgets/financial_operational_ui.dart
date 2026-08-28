import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class FinancialOperationalCard extends StatelessWidget {
  const FinancialOperationalCard(
      {Key? key, required this.child, this.onTap, this.onLongPress})
      : super(key: key);

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: .04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class FinancialMiniChip extends StatelessWidget {
  const FinancialMiniChip(
      {Key? key, required this.label, required this.color, this.icon})
      : super(key: key);
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

class FinancialFilterChip extends StatelessWidget {
  const FinancialFilterChip(
      {Key? key,
      required this.label,
      required this.selected,
      required this.onTap})
      : super(key: key);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(end: 7.w),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.operationalPurple : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                  color: selected
                      ? AppColors.operationalPurple
                      : AppColors.operationalCardBorder),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? Colors.white : AppColors.operationalNavy)),
          ),
        ),
      );
}

class FinancialGroupTitle extends StatelessWidget {
  const FinancialGroupTitle({Key? key, required this.title, this.count})
      : super(key: key);
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 5.h),
        child: Row(children: [
          Container(
              width: 4.w,
              height: 18.h,
              decoration: BoxDecoration(
                  color: AppColors.operationalPurple,
                  borderRadius: BorderRadius.circular(4.r))),
          SizedBox(width: 7.w),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.operationalNavy))),
          if (count != null)
            FinancialMiniChip(
                label: '$count', color: AppColors.operationalPurple),
        ]),
      );
}

class FinancialSectionToolbar extends StatelessWidget {
  const FinancialSectionToolbar({
    Key? key,
    required this.onSearch,
    required this.onFilter,
    required this.onReset,
    this.onReports,
    this.extraAction,
  }) : super(key: key);

  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onReset;
  final VoidCallback? onReports;
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        child: Row(children: [
          _FinancialToolbarButton(
              label: 'بحث', icon: Icons.search_rounded, onTap: onSearch),
          _FinancialToolbarButton(
              label: 'الفلاتر', icon: Icons.tune_rounded, onTap: onFilter),
          if (onReports != null)
            _FinancialToolbarButton(
                label: 'التقارير',
                icon: Icons.assessment_outlined,
                highlighted: true,
                onTap: onReports!),
          if (extraAction != null) extraAction!,
          _FinancialToolbarButton(
              label: 'إعادة ضبط',
              icon: Icons.restart_alt_rounded,
              onTap: onReset),
        ]),
      );
}

class _FinancialToolbarButton extends StatelessWidget {
  const _FinancialToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(end: 7.w),
        child: Material(
          color: highlighted
              ? AppColors.operationalPurple
              : ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: highlighted
                      ? AppColors.operationalPurple
                      : AppColors.operationalCardBorder,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 16.sp,
                    color: highlighted
                        ? Colors.white
                        : AppColors.operationalPurple),
                SizedBox(width: 5.w),
                Text(label,
                    style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: highlighted
                            ? Colors.white
                            : ThemeService.isDark.value
                                ? Colors.white
                                : AppColors.operationalNavy)),
              ]),
            ),
          ),
        ),
      );
}
