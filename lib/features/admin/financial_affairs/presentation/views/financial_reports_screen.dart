import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/assets_controller.dart';
import '../controllers/expenses_controller.dart';

enum FinancialReportsKind { expenses, assets }

Future<void> showFinancialReportsModal(
  BuildContext context, {
  required FinancialReportsKind kind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FinancialReportsModal(kind: kind),
  );
}

class _FinancialReportsModal extends StatefulWidget {
  const _FinancialReportsModal({required this.kind});

  final FinancialReportsKind kind;

  @override
  State<_FinancialReportsModal> createState() => _FinancialReportsModalState();
}

class _FinancialReportsModalState extends State<_FinancialReportsModal> {
  _FinancialReportDefinition? selectedReport;

  List<_FinancialReportDefinition> get reports =>
      widget.kind == FinancialReportsKind.expenses
          ? const [
              _FinancialReportDefinition(
                title: 'تقرير جميع المصاريف',
                subtitle: 'جميع المصاريف ضمن الفترة المحددة',
                keyName: '',
                icon: Icons.receipt_long_outlined,
              ),
              _FinancialReportDefinition(
                title: 'المصاريف العمومية',
                subtitle: 'المصاريف التشغيلية والإدارية',
                keyName: 'general',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _FinancialReportDefinition(
                title: 'مصاريف الرواتب',
                subtitle: 'حركة الرواتب والمدفوعات',
                keyName: 'salary',
                icon: Icons.badge_outlined,
              ),
              _FinancialReportDefinition(
                title: 'إتلاف البضاعة',
                subtitle: 'تكلفة وكميات المنتجات التالفة',
                keyName: 'destruction',
                icon: Icons.delete_sweep_outlined,
              ),
            ]
          : const [
              _FinancialReportDefinition(
                title: 'سجل الإهلاك الكامل',
                subtitle: 'جميع حركات إهلاك الأصول',
                keyName: '',
                icon: Icons.stacked_line_chart_outlined,
              ),
              _FinancialReportDefinition(
                title: 'إهلاك الشهر الحالي',
                subtitle: 'الحركات المسجلة لهذا الشهر',
                keyName: 'current_month',
                icon: Icons.calendar_month_outlined,
              ),
              _FinancialReportDefinition(
                title: 'عرض سجل الإهلاك',
                subtitle: 'فتح السجل التفصيلي للأصول',
                keyName: 'logs',
                icon: Icons.history_rounded,
              ),
            ];

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return FractionallySizedBox(
      heightFactor: .82,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkColor : AppColors.operationalSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 9.h),
              decoration: BoxDecoration(
                color: AppColors.customGreyColor5.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 8.h),
              child: Row(
                children: [
                  if (selectedReport != null)
                    IconButton(
                      tooltip: 'العودة للتقارير',
                      onPressed: () => setState(() => selectedReport = null),
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                    )
                  else
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color:
                            AppColors.operationalPurple.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(
                        Icons.assessment_outlined,
                        color: AppColors.operationalPurple,
                      ),
                    ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedReport?.title ??
                              (widget.kind == FinancialReportsKind.expenses
                                  ? 'تقارير المصاريف'
                                  : 'تقارير الأصول والإهلاك'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : AppColors.operationalNavy,
                          ),
                        ),
                        Text(
                          selectedReport == null
                              ? 'اختر التقرير المطلوب ثم صيغة التنزيل'
                              : _filterSummary(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selectedReport == null
                    ? _reportsGrid()
                    : _reportActions(selectedReport!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportsGrid() => LayoutBuilder(
        key: const ValueKey('reports-grid'),
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 2;
          return GridView.builder(
            padding: EdgeInsets.all(14.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 9.w,
              mainAxisSpacing: 9.h,
              childAspectRatio: constraints.maxWidth >= 500 ? 2.15 : 1.25,
            ),
            itemCount: reports.length,
            itemBuilder: (_, index) {
              final report = reports[index];
              return _FinancialReportCard(
                report: report,
                onTap: () {
                  if (report.keyName == 'logs') {
                    Navigator.of(context).pop();
                    final controller = Get.find<AssetsController>();
                    controller.getAssetsLogs();
                    Get.toNamed(AppRoutes.ASSETLOGSCREEN);
                    return;
                  }
                  setState(() => selectedReport = report);
                },
              );
            },
          );
        },
      );

  Widget _reportActions(_FinancialReportDefinition report) => ListView(
        key: ValueKey('report-actions-${report.keyName}'),
        padding: EdgeInsets.all(16.r),
        children: [
          _ReportInfoCard(report: report, summary: _filterSummary()),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('تعديل فلاتر التقرير'),
          ),
          SizedBox(height: 16.h),
          Text(
            'صيغة التنزيل',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          if (widget.kind == FinancialReportsKind.expenses) ...[
            _ExportButton(
              label: 'تنزيل PDF',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () => _downloadExpense('pdf'),
            ),
            _ExportButton(
              label: 'تنزيل Excel',
              icon: Icons.table_chart_outlined,
              onTap: () => _downloadExpense('xlsx'),
            ),
            _ExportButton(
              label: 'تنزيل CSV',
              icon: Icons.grid_on_outlined,
              onTap: () => _downloadExpense('csv'),
            ),
          ] else
            _ExportButton(
              label: 'تنزيل تقرير PDF',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () {
                final period = report.keyName == 'current_month'
                    ? DateFormat('yyyy-MM').format(DateTime.now())
                    : '';
                Get.find<AssetsController>()
                    .downloadReport(periodOverride: period);
              },
            ),
        ],
      );

  void _showFilters() {
    if (widget.kind == FinancialReportsKind.expenses) {
      final controller = Get.find<ExpensesController>();
      showCustomDialog(
        context,
        fromDateController: controller.fromController,
        toDateController: controller.toController,
        label: 'فلاتر تقرير المصاريف',
        onPressed: Get.back,
        onClear: () {
          controller.fromController.clear();
          controller.toController.clear();
          Get.back();
        },
      );
      return;
    }

    final controller = Get.find<AssetsController>();
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('كل فترات الإهلاك'),
                onTap: () {
                  controller.assetLogPeriodFilter.value = '';
                  Navigator.of(sheetContext).pop();
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('الشهر الحالي'),
                subtitle: Text(currentMonth),
                onTap: () {
                  controller.assetLogPeriodFilter.value = currentMonth;
                  Navigator.of(sheetContext).pop();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterSummary() {
    if (widget.kind == FinancialReportsKind.expenses) {
      final controller = Get.find<ExpensesController>();
      if (controller.fromController.text.isEmpty &&
          controller.toController.text.isEmpty) {
        return 'الفترة: جميع التواريخ';
      }
      return 'من ${controller.fromController.text.isEmpty ? 'البداية' : controller.fromController.text} إلى ${controller.toController.text.isEmpty ? 'اليوم' : controller.toController.text}';
    }
    final period = Get.find<AssetsController>().assetLogPeriodFilter.value;
    return period.isEmpty ? 'الفترة: جميع الأشهر' : 'الفترة: $period';
  }

  void _downloadExpense(String format) {
    Get.find<ExpensesController>().downloadExpenseReport(
      format,
      expenseTypeOverride: selectedReport?.keyName,
    );
  }
}

class _FinancialReportCard extends StatelessWidget {
  const _FinancialReportCard({required this.report, required this.onTap});

  final _FinancialReportDefinition report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(15.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.r),
          child: Container(
            padding: EdgeInsets.all(11.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: AppColors.operationalCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color:
                            AppColors.operationalPurple.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(report.icon,
                          color: AppColors.operationalPurple, size: 19.sp),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.operationalPurple, size: 16),
                  ],
                ),
                const Spacer(),
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3.h),
                Text(
                  report.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9.sp, color: AppColors.customGreyColor5),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard({required this.report, required this.summary});

  final _FinancialReportDefinition report;
  final String summary;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(13.r),
        decoration: BoxDecoration(
          color: AppColors.operationalPurple.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: AppColors.operationalPurple.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Icon(report.icon, color: AppColors.operationalPurple, size: 25.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3.h),
                  Text(summary,
                      style: TextStyle(
                          fontSize: 10.sp, color: AppColors.customGreyColor5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: const BorderSide(color: AppColors.operationalCardBorder),
          ),
          tileColor: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor,
          leading: Icon(icon, color: AppColors.operationalPurple),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.download_rounded),
        ),
      );
}

class _FinancialReportDefinition {
  const _FinancialReportDefinition({
    required this.title,
    required this.subtitle,
    required this.keyName,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String keyName;
  final IconData icon;
}
