import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

/// Temporary labels while investigating legacy vs V2 duplicate tasks.
class TaskSourceDebug {
  static bool get isVisible => kDebugMode;

  static String label({
    required String source,
    required int taskId,
    int? occurrenceId,
    int? templateId,
    String? parentId,
    bool isVirtualDay = false,
  }) {
    final src = source.trim().toLowerCase();
    if (src == 'occurrence') {
      final occ = occurrenceId ?? taskId;
      final parts = <String>['V2', 'تكرار:$occ'];
      if (templateId != null && templateId > 0) {
        parts.add('قالب:$templateId');
      }
      if (taskId > 0 && taskId != occ) {
        parts.add('مهمة:$taskId');
      }
      return parts.join(' · ');
    }

    if (parentId != null && parentId.isNotEmpty && parentId != '0') {
      return 'نسخة قديمة · مهمة:$taskId · أصل:$parentId';
    }

    if (isVirtualDay) {
      return 'توسيع افتراضي · مهمة:$taskId';
    }

    final parts = <String>['قديم', 'مهمة:$taskId'];
    if (templateId != null && templateId > 0) {
      parts.add('قالب:$templateId');
    }
    return parts.join(' · ');
  }
}

class TaskSourceDebugBadge extends StatelessWidget {
  const TaskSourceDebugBadge({
    Key? key,
    required this.label,
  }) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    if (!TaskSourceDebug.isVisible || label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.customGreyColor5.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: AppColors.customGreyColor5.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              height: 1.25,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: AppColors.customGreyColor5,
            ),
          ),
        ),
      ),
    );
  }
}
