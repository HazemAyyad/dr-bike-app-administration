import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/employee_points_log_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';
import '../../data/repositorie_imp/employee_implement.dart';

/// Simple reusable dialog that fetches and lists a single employee's points
/// log entries for the selected month/year. Used by the global screen and
/// the reports screen when the admin clicks "View logs".
class EmployeePointsLogsDialog extends StatefulWidget {
  const EmployeePointsLogsDialog({
    Key? key,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
  }) : super(key: key);

  final int employeeId;
  final String employeeName;
  final int month;
  final int year;

  @override
  State<EmployeePointsLogsDialog> createState() =>
      _EmployeePointsLogsDialogState();
}

class _EmployeePointsLogsDialogState
    extends State<EmployeePointsLogsDialog> {
  final List<EmployeePointsLogModel> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usecase = GetEmployeePointsLogsUsecase(
        employeeRepository: Get.find<EmployeeImplement>(),
      );
      final page = await usecase.call(
        employeeId: widget.employeeId,
        month: widget.month,
        year: widget.year,
        perPage: 200,
      );
      setState(() => _logs
        ..clear()
        ..addAll(page.items));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.employeeName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: const CircularProgressIndicator(),
                )
              else if (_error != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFDC2626))),
                )
              else if (_logs.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text(
                    'pointsReportNoLogs'.tr,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: 6.h),
                    itemBuilder: (_, i) => _LogTile(log: _logs[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final EmployeePointsLogModel log;

  @override
  Widget build(BuildContext context) {
    final accent =
        log.isAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = (Get.locale?.languageCode == 'ar'
            ? log.categoryNameAr
            : log.categoryNameEn) ??
        log.category;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.isAdd ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
            color: accent,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${log.isAdd ? '+' : '-'}${log.points}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                if (log.reason != null && log.reason!.isNotEmpty)
                  Text(log.reason!,
                      style: const TextStyle(color: Color(0xFF6B7280))),
                if (log.pointsDate != null)
                  Text(log.pointsDate!,
                      style: TextStyle(
                          color: const Color(0xFF9CA3AF), fontSize: 11.sp)),
                if (log.createdByName != null)
                  Text(log.createdByName!,
                      style: TextStyle(
                          color: const Color(0xFF9CA3AF), fontSize: 11.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
