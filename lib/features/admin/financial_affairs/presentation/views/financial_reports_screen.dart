import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/assets_controller.dart';
import '../controllers/expenses_controller.dart';

enum FinancialReportsKind { expenses, assets }

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({
    Key? key,
    required this.kind,
  }) : super(key: key);

  final FinancialReportsKind kind;

  @override
  Widget build(BuildContext context) {
    final reports = kind == FinancialReportsKind.expenses
        ? const <_FinancialReportDefinition>[
            _FinancialReportDefinition(
                title: 'تقرير جميع المصاريف',
                keyName: '',
                icon: Icons.receipt_long_outlined),
            _FinancialReportDefinition(
                title: 'تقرير المصاريف العمومية',
                keyName: 'general',
                icon: Icons.account_balance_wallet_outlined),
            _FinancialReportDefinition(
                title: 'تقرير مصاريف الرواتب',
                keyName: 'salary',
                icon: Icons.badge_outlined),
            _FinancialReportDefinition(
                title: 'تقرير إتلاف البضاعة',
                keyName: 'destruction',
                icon: Icons.delete_sweep_outlined),
          ]
        : const <_FinancialReportDefinition>[
            _FinancialReportDefinition(
                title: 'تقرير سجل الإهلاك الكامل',
                keyName: '',
                icon: Icons.stacked_line_chart_outlined),
            _FinancialReportDefinition(
                title: 'تقرير إهلاك الشهر الحالي',
                keyName: 'current_month',
                icon: Icons.calendar_month_outlined),
            _FinancialReportDefinition(
                title: 'عرض سجل الإهلاك',
                keyName: 'logs',
                icon: Icons.history_rounded),
          ];

    return Scaffold(
      appBar: CustomAppBar(
        title: kind == FinancialReportsKind.expenses
            ? 'تقارير المصاريف'
            : 'تقارير الأصول والإهلاك',
        action: false,
        actions: [
          IconButton(
            tooltip: 'الفلاتر',
            onPressed: () => _showFilters(context),
            icon: Icon(
              Icons.tune_rounded,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth < 340
                ? 2
                : 3;
        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 7.w,
            mainAxisSpacing: 7.h,
            childAspectRatio: constraints.maxWidth > 420 ? 2.75 : 1.62,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _FinancialReportCard(
              title: report.title,
              icon: report.icon,
              onTap: () => _openReport(context, report),
            );
          },
        );
      }),
    );
  }

  void _showFilters(BuildContext context) {
    if (kind == FinancialReportsKind.expenses) {
      final controller = Get.find<ExpensesController>();
      showCustomDialog(
        context,
        fromDateController: controller.fromController,
        toDateController: controller.toController,
        label: 'فلاتر تقرير المصاريف',
        onPressed: Get.back,
      );
      return;
    }
    final controller = Get.find<AssetsController>();
    _showAssetPeriodSheet(context, controller);
  }

  void _openReport(BuildContext context, _FinancialReportDefinition report) {
    if (kind == FinancialReportsKind.assets && report.keyName == 'logs') {
      final controller = Get.find<AssetsController>();
      controller.getAssetsLogs();
      Get.toNamed(AppRoutes.ASSETLOGSCREEN);
      return;
    }
    Get.to(() => _FinancialReportExportScreen(
          kind: kind,
          report: report,
        ));
  }
}

class _FinancialReportExportScreen extends StatelessWidget {
  const _FinancialReportExportScreen({
    required this.kind,
    required this.report,
  });

  final FinancialReportsKind kind;
  final _FinancialReportDefinition report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: report.title,
        action: false,
        actions: [
          IconButton(
            tooltip: 'الفلاتر',
            onPressed: () {
              if (kind == FinancialReportsKind.expenses) {
                final c = Get.find<ExpensesController>();
                showCustomDialog(context,
                    fromDateController: c.fromController,
                    toDateController: c.toController,
                    label: 'فلاتر التقرير',
                    onPressed: Get.back);
              } else {
                _showAssetPeriodSheet(context, Get.find<AssetsController>());
              }
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor4
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: .24)),
            ),
            child: Row(children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(report.icon,
                    color: AppColors.primaryColor, size: 22.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(report.title,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3.h),
                    Text(_filterSummary(),
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.customGreyColor5)),
                  ])),
            ]),
          ),
          SizedBox(height: 14.h),
          Text('تنزيل التقرير',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 7.h),
          if (kind == FinancialReportsKind.expenses) ...[
            _ExportAction(
                label: 'تنزيل PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () => _downloadExpense('pdf')),
            _ExportAction(
                label: 'تنزيل Excel',
                icon: Icons.table_chart_outlined,
                onTap: () => _downloadExpense('xlsx')),
            _ExportAction(
                label: 'تنزيل CSV',
                icon: Icons.grid_on_outlined,
                onTap: () => _downloadExpense('csv')),
          ] else
            _ExportAction(
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
      ),
    );
  }

  String _filterSummary() {
    if (kind == FinancialReportsKind.expenses) {
      final c = Get.find<ExpensesController>();
      if (c.fromController.text.isEmpty && c.toController.text.isEmpty) {
        return 'كل الفترات';
      }
      return 'من ${c.fromController.text.isEmpty ? 'البداية' : c.fromController.text} إلى ${c.toController.text.isEmpty ? 'اليوم' : c.toController.text}';
    }
    return report.keyName == 'current_month'
        ? DateFormat('yyyy-MM').format(DateTime.now())
        : 'كل فترات الإهلاك';
  }

  void _downloadExpense(String format) {
    Get.find<ExpensesController>()
        .downloadExpenseReport(format, expenseTypeOverride: report.keyName);
  }
}

class _ExportAction extends StatelessWidget {
  const _ExportAction(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 7.h),
        child: _FinancialReportCard(title: label, icon: icon, onTap: onTap),
      );
}

class _FinancialReportCard extends StatelessWidget {
  const _FinancialReportCard(
      {required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = ThemeService.isDark.value
        ? AppColors.customGreyColor4
        : AppColors.whiteColor2;
    return InkWell(
      borderRadius: BorderRadius.circular(6.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6.r),
          border:
              Border.all(color: AppColors.primaryColor.withValues(alpha: .24)),
        ),
        child: Row(children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 16.sp),
          ),
          SizedBox(width: 6.w),
          Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5.sp, fontWeight: FontWeight.w800))),
          Icon(Icons.chevron_left_rounded,
              color: AppColors.primaryColor, size: 18.sp),
        ]),
      ),
    );
  }
}

class _FinancialReportDefinition {
  const _FinancialReportDefinition(
      {required this.title, required this.keyName, required this.icon});
  final String title;
  final String keyName;
  final IconData icon;
}

void _showAssetPeriodSheet(BuildContext context, AssetsController controller) {
  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.tune_rounded, color: AppColors.primaryColor),
              SizedBox(width: 8.w),
              Text('فلاتر التقرير',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(onPressed: Get.back, icon: const Icon(Icons.close)),
            ]),
            ListTile(
              title: const Text('كل فترات الإهلاك'),
              onTap: () {
                controller.assetLogPeriodFilter.value = '';
                Get.back();
              },
            ),
            ListTile(
              title: const Text('الشهر الحالي'),
              subtitle: Text(currentMonth),
              onTap: () {
                controller.assetLogPeriodFilter.value = currentMonth;
                Get.back();
              },
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
