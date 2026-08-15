import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class CustomLineSteps extends StatelessWidget {
  const CustomLineSteps({
    Key? key,
    required this.timeLineSteps,
    required this.selectedStep,
    required this.changeSelected,
    this.width,
    this.isTaped = false,
  }) : super(key: key);

  final List<Map<int, String>> timeLineSteps;
  final RxInt selectedStep;
  final Function(int index) changeSelected;
  final bool isTaped;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor.withValues(alpha: 0.35)
              : AppColors.customGreyColor7,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            for (final entry in timeLineSteps.asMap().entries) ...[
              Expanded(
                child: _CompactStep(
                  index: entry.key + 1,
                  label: entry.value.values.first.tr,
                  selectedStep: selectedStep.value,
                  textTheme: textTheme,
                  onTap: isTaped ? () => changeSelected(entry.key + 1) : null,
                ),
              ),
              if (entry.key + 1 < timeLineSteps.length)
                Container(
                  width: width ?? 24.w,
                  height: 2.h,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: entry.key + 1 < selectedStep.value
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStep extends StatelessWidget {
  const _CompactStep({
    required this.index,
    required this.label,
    required this.selectedStep,
    required this.textTheme,
    this.onTap,
  });

  final int index;
  final String label;
  final int selectedStep;
  final TextStyle textTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedStep == index;
    final isDone = selectedStep > index;
    final color =
        isSelected || isDone ? AppColors.primaryColor : Colors.grey.shade400;
    final bg = isDone
        ? AppColors.primaryColor
        : isSelected
            ? AppColors.primaryColor.withValues(alpha: 0.12)
            : ThemeService.isDark.value
                ? AppColors.customGreyColor
                : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: isSelected ? 1.4 : 1),
            ),
            child: Center(
              child: isDone
                  ? Icon(Icons.check_rounded, size: 16.sp, color: Colors.white)
                  : Text(
                      '$index',
                      style: textTheme.copyWith(
                        fontSize: 12.sp,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.copyWith(
              fontSize: 10.sp,
              height: 1.1,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
