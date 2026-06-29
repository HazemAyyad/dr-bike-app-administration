import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';
import '../utils/overtime_duration_format.dart';

class AttendanceOvertimeRequestCard extends StatelessWidget {
  const AttendanceOvertimeRequestCard({
    Key? key,
    required this.request,
    required this.controller,
  }) : super(key: key);

  final Map<String, dynamic> request;
  final EmployeeSectionController controller;

  @override
  Widget build(BuildContext context) {
    final name = request['employee_name']?.toString() ?? '';
    final date = request['work_date']?.toString() ?? '';
    final minutes =
        int.tryParse(request['requested_minutes']?.toString() ?? '') ?? 0;
    final duration = formatOvertimeMinutes(minutes);
    final source = request['checkout_source']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.more_time,
              color: AppColors.primaryColor,
              size: 19.sp,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$duration  •  $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (source.isNotEmpty)
                  Text(
                    '${'checkoutSourceLabel'.tr}: $source',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5.sp, color: Colors.black54),
                  ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints.tightFor(width: 36.w, height: 36.w),
            padding: EdgeInsets.zero,
            tooltip: 'reject'.tr,
            style: IconButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              backgroundColor: Colors.red.shade50,
            ),
            onPressed: () => controller.rejectAttendanceOvertimeRequest(
              int.parse(request['id'].toString()),
            ),
            icon: Icon(Icons.close_rounded, size: 20.sp),
          ),
          SizedBox(width: 5.w),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints.tightFor(width: 36.w, height: 36.w),
            padding: EdgeInsets.zero,
            tooltip: 'approve'.tr,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primaryColor,
            ),
            onPressed: () => controller.approveAttendanceOvertimeRequest(
              int.parse(request['id'].toString()),
              approvedMinutes: minutes,
            ),
            icon: Icon(Icons.check_rounded, size: 20.sp),
          ),
        ],
      ),
    );
  }
}
