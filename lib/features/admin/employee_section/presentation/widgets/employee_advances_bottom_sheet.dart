import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';

/// Advances for one employee (month scope). Opened from the entitlements card, not from financial details.
void showEmployeeAdvancesBottomSheet(
  BuildContext context, {
  required EmployeeSectionController controller,
  required int employeeId,
  required String employeeName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EmployeeAdvancesSheet(
      controller: controller,
      employeeId: employeeId,
      employeeName: employeeName,
    ),
  );
}

class _EmployeeAdvancesSheet extends StatefulWidget {
  const _EmployeeAdvancesSheet({
    required this.controller,
    required this.employeeId,
    required this.employeeName,
  });

  final EmployeeSectionController controller;
  final int employeeId;
  final String employeeName;

  @override
  State<_EmployeeAdvancesSheet> createState() => _EmployeeAdvancesSheetState();
}

class _EmployeeAdvancesSheetState extends State<_EmployeeAdvancesSheet> {
  late DateTime _monthStart;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _monthStart = DateTime(n.year, n.month, 1);
    _load();
  }

  void _load() {
    widget.controller.loadEmployeeAdvancesFor(
      widget.employeeId,
      widget.controller.formatMonthKey(_monthStart),
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month + delta, 1);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeService.isDark.value;
      final result = widget.controller.employeeAdvances.value;
      final advances = result?.advances ?? const [];

      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'advances'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  IconButton(
                    tooltip: 'previousMonth'.tr,
                    onPressed: () => _shiftMonth(-1),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.primaryColor,
                      size: 28.sp,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.controller.formatMonthLabel(_monthStart),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'nextMonth'.tr,
                    onPressed: () => _shiftMonth(1),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryColor,
                      size: 28.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (widget.controller.isAdvancesLoading.value)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.h),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (widget.controller.advancesError.value.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(widget.controller.advancesError.value),
                  ),
                )
              else if (advances.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 42.sp,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 8.h),
                        Text('noAdvancesForMonth'.tr),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: advances.length,
                    separatorBuilder: (_, __) => Divider(height: 1.h),
                    itemBuilder: (_, index) {
                      final advance = advances[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primaryColor.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.payments_outlined,
                            color: AppColors.primaryColor,
                            size: 20.sp,
                          ),
                        ),
                        title: Text(
                          '${advance.amount} ${'currency'.tr}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${advance.status} · ${advance.day} · ${advance.date} · ${advance.time}',
                        ),
                      );
                    },
                  ),
                ),
              Divider(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'totalAdvances'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${result?.total ?? '0'} ${'currency'.tr}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
