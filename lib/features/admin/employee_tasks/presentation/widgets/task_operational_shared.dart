import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class TaskOpCard extends StatelessWidget {
  const TaskOpCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.compact = false,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(bottom: compact ? 8.h : 14.h),
      padding: padding ?? EdgeInsets.all(compact ? 10.w : 18.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(compact ? 12.r : 22.r),
        border: Border.all(color: AppColors.operationalCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TaskSectionTitle extends StatelessWidget {
  const TaskSectionTitle(this.title, {Key? key, this.compact = false})
      : super(key: key);

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: compact ? 6.h : 12.h,
        right: 4.w,
        left: 4.w,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title.tr,
          style: TextStyle(
            fontSize: compact ? 12.sp : 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.operationalNavy,
          ),
        ),
      ),
    );
  }
}

class TaskStickyCta extends StatelessWidget {
  const TaskStickyCta({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.operationalNavy,
              disabledBackgroundColor: AppColors.customGreyColor5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        label.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class TaskSegmentedOption extends StatelessWidget {
  const TaskSegmentedOption({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? AppColors.operationalPurple
                  : AppColors.operationalCardBorder,
            ),
          ),
          child: Text(
            label.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.operationalNavy,
            ),
          ),
        ),
      ),
    );
  }
}
