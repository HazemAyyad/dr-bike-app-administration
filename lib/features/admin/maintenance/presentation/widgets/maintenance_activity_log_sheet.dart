import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/maintenance_activity_log_model.dart';

void showMaintenanceActivityLogSheet(
  BuildContext context,
  List<MaintenanceActivityLogModel> logs,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MaintenanceActivityLogSheet(logs: logs),
  );
}

class _MaintenanceActivityLogSheet extends StatelessWidget {
  const _MaintenanceActivityLogSheet({required this.logs});

  final List<MaintenanceActivityLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.94.sh),
        margin: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.h),
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'maintenanceActivityLog'.tr,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            if (logs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Center(child: Text('noData'.tr)),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.only(top: 8.h),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 6.h),
                  itemBuilder: (_, index) {
                    final log = logs[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.customGreyColor
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.title,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (log.description.trim().isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              log.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          ],
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 5.h,
                            children: [
                              _chip(Icons.person_outline, log.actorName),
                              _chip(Icons.access_time, log.createdAt),
                              if (log.oldStatus != null &&
                                  log.newStatus != null)
                                _chip(
                                  Icons.compare_arrows,
                                  '${_statusLabel(log.oldStatus)} > ${_statusLabel(log.newStatus)}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primaryColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'new':
        return 'صيانة جديدة';
      case 'ongoing':
        return 'قيد العمل';
      case 'ready':
        return 'جاهزة للتسليم';
      case 'delivered':
        return 'تم التسليم';
      case null:
      case '':
        return '-';
      default:
        return status ?? '-';
    }
  }
}
