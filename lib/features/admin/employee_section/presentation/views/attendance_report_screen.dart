import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/attendance_report_model.dart';
import '../controllers/attendance_report_controller.dart';

class AttendanceReportScreen extends GetView<AttendanceReportController> {
  const AttendanceReportScreen({Key? key}) : super(key: key);

  static String _weeklyOffFormatted(List<String> days) {
    if (days.isEmpty) return '—';
    return days.map((d) => 'day_${d.toLowerCase()}'.tr).join(', ');
  }

  static String _reportTypeBadge(String code) {
    switch (code) {
      case 'daily':
        return 'reportTypeDaily'.tr;
      case 'weekly':
        return 'reportTypeWeekly'.tr;
      case 'monthly':
        return 'reportTypeMonthly'.tr;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconClr = ThemeService.isDark.value
        ? AppColors.primaryColor
        : AppColors.secondaryColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'attendanceReportTitle',
        action: false,
        actions: [
          IconButton(
            tooltip: 'attendanceReportFilterFromScreen'.tr,
            icon: Icon(Icons.tune_rounded, color: iconClr),
            onPressed: () => controller.openFilterDialog(context),
          ),
          Obx(() {
            final ready = controller.result.value != null;
            return PopupMenuButton<String>(
              tooltip: 'exportReportMenu'.tr,
              enabled: ready,
              icon: Icon(Icons.print_outlined, color: iconClr),
              onSelected: (v) async {
                switch (v) {
                  case 'pdf_share':
                    await controller.exportPdfShare();
                    break;
                  case 'pdf_save':
                    await controller.exportPdfSaveAndOpen();
                    break;
                  case 'pdf_print':
                    await controller.printPdf();
                    break;
                  case 'excel_csv':
                    await controller.exportExcelCsv();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'pdf_share',
                  child: Text('exportPdfShare'.tr),
                ),
                PopupMenuItem<String>(
                  value: 'pdf_save',
                  child: Text('exportPdfSave'.tr),
                ),
                PopupMenuItem<String>(
                  value: 'pdf_print',
                  child: Text('exportPdfPrint'.tr),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'excel_csv',
                  child: Text('exportExcelCsv'.tr),
                ),
              ],
            );
          }),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.errorMessage.value != null &&
            controller.result.value == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48.sp, color: AppColors.primaryColor),
                  SizedBox(height: 12.h),
                  Text(
                    controller.errorMessage.value ?? '',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  TextButton.icon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    label: Text('tryAgain'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final r = controller.result.value;
        if (r == null) {
          return Center(child: Text('reportEmptyState'.tr));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_reportTypeBadge(r.reportType)} · ${r.month}/${r.year}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${'periodLabel'.tr}: ${r.periodFrom} → ${r.periodTo}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (r.reportType == 'daily' && r.day != null)
                    Text(
                      '${'dayLabel'.tr}: ${r.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (r.reportType == 'weekly' && r.week != null)
                    Text(
                      '${'weekOfMonthLabel'.tr}: ${r.week}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  SizedBox(height: 8.h),
                  Text(
                    'earnedSalaryAttendanceHint'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: ThemeService.isDark.value
                ? Colors.white24
                : Colors.grey.shade300),
            Expanded(
              child: r.employees.isEmpty
                  ? Center(child: Text('reportEmptyState'.tr))
                  : LayoutBuilder(
                      builder: (context, _) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 24.h),
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth:
                                  MediaQuery.sizeOf(context).width - 8.w,
                            ),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.resolveWith((_) =>
                                      ThemeService.isDark.value
                                          ? Colors.white10
                                          : Colors.grey.shade50),
                              columnSpacing: 16.w,
                              horizontalMargin: 12.w,
                              columns: [
                                DataColumn(
                                    label:
                                        Text('employeeNameReportCol'.tr)),
                                DataColumn(
                                    label:
                                        Text('weeklyDaysOffTitle'.tr)),
                                DataColumn(
                                  label: Text('hourWorkPriceReportCol'.tr),
                                ),
                                DataColumn(
                                  label:
                                      Text('overtimeHourPriceEffectiveCol'.tr),
                                ),
                                DataColumn(
                                    label: Text(
                                        'requiredWorkingDaysCol'.tr)),
                                DataColumn(
                                    label:
                                        Text('requiredHoursLabel'.tr)),
                                DataColumn(
                                    label: Text('workedHoursLabel'.tr)),
                                DataColumn(
                                    label:
                                        Text('normalHoursLabel'.tr)),
                                DataColumn(
                                    label:
                                        Text('overtimeHoursLabel'.tr)),
                                DataColumn(label: Text('normalSalaryReportCol'.tr)),
                                DataColumn(
                                    label: Text(
                                        'overtimeSalaryReportCol'.tr)),
                                DataColumn(
                                    label:
                                        Text('salaryForWorkedHoursCol'.tr),
                                ),
                                DataColumn(
                                  label: Text('employeeDebtsReportCol'.tr),
                                ),
                              ],
                              rows: r.employees
                                  .map((e) => _row(context, e))
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  DataRow _row(BuildContext context, AttendanceReportEmployeeRow e) {
    return DataRow(
      cells: [
        DataCell(SizedBox(
          width: 120.w,
          child: Text(
            e.employeeName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        )),
        DataCell(Text(
          _weeklyOffFormatted(e.weeklyDaysOff),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        )),
        DataCell(Text(e.hourWorkPrice)),
        DataCell(Text(e.overtimeHourPriceEffective)),
        DataCell(Text('${e.requiredWorkingDays}')),
        DataCell(Text(e.requiredHours)),
        DataCell(Text(e.workedHours)),
        DataCell(Text(e.normalHours)),
        DataCell(Text(e.overtimeHours)),
        DataCell(Text(e.normalSalary)),
        DataCell(Text(e.overtimeSalary)),
        DataCell(Text(
          e.totalSalary,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600),
        )),
        DataCell(Text(e.employeeDebts)),
      ],
    );
  }
}
