import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

/// White card section used in operational task composer screens.
class TaskFormSectionCard extends StatelessWidget {
  const TaskFormSectionCard({
    Key? key,
    required this.title,
    required this.child,
    this.trailing,
    this.compact = false,
  }) : super(key: key);

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 8.h : 16.h),
      padding: EdgeInsets.all(compact ? 10.w : 16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(compact ? 12.r : 16.r),
        border: Border.all(color: AppColors.operationalCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.tr,
                  style: TextStyle(
                    fontSize: compact ? 12.sp : 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: compact ? 8.h : 12.h),
          child,
        ],
      ),
    );
  }
}
