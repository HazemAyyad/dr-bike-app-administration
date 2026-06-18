import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';

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
    final minutes = int.tryParse(request['requested_minutes']?.toString() ?? '') ?? 0;
    final hours = (minutes / 60).toStringAsFixed(2);
    final source = request['checkout_source']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.more_time, color: Colors.orange.shade800, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '$date · $hours ${'hours'.tr}',
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
          if (source.isNotEmpty)
            Text(
              '${'checkoutSourceLabel'.tr}: $source',
              style: TextStyle(fontSize: 11.sp, color: Colors.black54),
            ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.rejectAttendanceOvertimeRequest(
                    int.parse(request['id'].toString()),
                  ),
                  child: Text('reject'.tr),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => controller.approveAttendanceOvertimeRequest(
                    int.parse(request['id'].toString()),
                    approvedMinutes: minutes,
                  ),
                  child: Text('approve'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
