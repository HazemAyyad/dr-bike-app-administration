import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/reports_controller.dart';

class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'التقارير',
        action: false,
      ),
      body: GetBuilder<ReportsController>(
        builder: (_) => LayoutBuilder(
          builder: (context, constraints) {
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
              itemCount: controller.reports.length,
              itemBuilder: (context, index) {
                final report = controller.reports[index];
                return _ReportCard(
                  title: report['title']!,
                  icon: _iconForReport(report['key']!),
                  enabled: report['key'] == 'sales',
                  onTap: () {
                    controller.openReport(report['key']!);
                    Get.toNamed(
                      AppRoutes.REPORTDETAILSCREEN,
                      arguments: report,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconForReport(String key) {
    switch (key) {
      case 'sales':
        return Icons.point_of_sale_outlined;
      case 'balances':
        return Icons.account_balance_wallet_outlined;
      case 'statement':
        return Icons.receipt_long_outlined;
      case 'checks':
        return Icons.fact_check_outlined;
      case 'boxes':
        return Icons.account_balance_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'income':
        return Icons.stacked_line_chart_outlined;
      case 'sales_returns':
        return Icons.assignment_return_outlined;
      default:
        return Icons.trending_up_outlined;
    }
  }
}

class ReportsDetailScreen extends GetView<ReportsController> {
  const ReportsDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, String>?;
    final reportKey = args?['key'] ?? controller.selectedReport.value;
    final title = args?['title'] ?? 'التقرير';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedReport.value != reportKey) {
        controller.openReport(reportKey);
      } else if (reportKey == 'sales' &&
          controller.salesRows.isEmpty &&
          !controller.isLoading.value) {
        controller.loadSalesReport();
      }
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        action: false,
        actions: [
          if (reportKey == 'sales')
            IconButton(
              tooltip: 'الفلاتر',
              onPressed: () => _showFiltersSheet(context, controller),
              icon: Icon(
                Icons.tune_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          if (reportKey == 'sales')
            IconButton(
              tooltip: 'PDF',
              onPressed: () =>
                  Get.snackbar('PDF', 'سيتم ربط تصدير PDF للتقرير'),
              icon: Icon(
                Icons.picture_as_pdf_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
        ],
      ),
      body: GetBuilder<ReportsController>(
        builder: (_) {
          if (reportKey != 'sales') {
            return _ComingSoon(controller: controller, reportTitle: title);
          }
          return RefreshIndicator(
            onRefresh: controller.loadSalesReport,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _SalesReport(controller: controller),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showFiltersSheet(BuildContext context, ReportsController controller) {
  Get.bottomSheet(
    GetBuilder<ReportsController>(
      builder: (_) => Container(
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
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primaryColor),
                  SizedBox(width: 8.w),
                  Text(
                    'فلاتر التقرير',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _FiltersBar(controller: controller, fullWidth: true),
              SizedBox(height: 12.h),
              FilledButton.icon(
                onPressed: () async {
                  await controller.loadSalesReport();
                  Get.back();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool enabled;
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
          border: Border.all(
            color:
                AppColors.primaryColor.withValues(alpha: enabled ? .24 : .10),
          ),
        ),
        child: Row(
          children: [
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
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primaryColor,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller, this.fullWidth = false});

  final ReportsController controller;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (fullWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterField(
            label: 'الفترة',
            child: _DropdownChip(
              value: controller.selectedPeriod.value,
              items: controller.periods,
              onChanged: controller.selectPeriod,
              fullWidth: true,
            ),
          ),
          if (controller.selectedPeriod.value == 'custom') ...[
            SizedBox(height: 10.h),
            _FilterField(
              label: 'من / إلى',
              child: OutlinedButton.icon(
                onPressed: () => controller.pickCustomRange(context),
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  controller.fromDate == null || controller.toDate == null
                      ? 'اختيار الفترة'
                      : '${_date(controller.fromDate!)} - ${_date(controller.toDate!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          SizedBox(height: 10.h),
          _FilterField(
            label: 'الحالة',
            child: _DropdownChip(
              value: controller.selectedStatus.value,
              items: controller.statuses,
              onChanged: controller.selectStatus,
              fullWidth: true,
            ),
          ),
          SizedBox(height: 10.h),
          _FilterField(
            label: 'طريقة الدفع',
            child: _DropdownChip(
              value: controller.selectedPaymentType.value,
              items: controller.paymentTypes,
              onChanged: controller.selectPaymentType,
              fullWidth: true,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DropdownChip(
          value: controller.selectedPeriod.value,
          items: controller.periods,
          onChanged: controller.selectPeriod,
        ),
        if (controller.selectedPeriod.value == 'custom')
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 260.w),
            child: OutlinedButton.icon(
              onPressed: () => controller.pickCustomRange(context),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                controller.fromDate == null || controller.toDate == null
                    ? 'اختيار الفترة'
                    : '${_date(controller.fromDate!)} - ${_date(controller.toDate!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        _DropdownChip(
          value: controller.selectedStatus.value,
          items: controller.statuses,
          onChanged: controller.selectStatus,
        ),
        _DropdownChip(
          value: controller.selectedPaymentType.value,
          items: controller.paymentTypes,
          onChanged: controller.selectPaymentType,
        ),
        IconButton.filledTonal(
          tooltip: 'تطبيق',
          onPressed: controller.loadSalesReport,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.secondaryColor,
          ),
        ),
        SizedBox(height: 5.h),
        child,
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
    this.fullWidth = false,
  });

  final String value;
  final List<Map<String, String>> items;
  final ValueChanged<String> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: fullWidth
          ? const BoxConstraints(minWidth: double.infinity)
          : BoxConstraints(
              minWidth: 128.w,
              maxWidth: 188.w,
            ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          border:
              Border.all(color: AppColors.primaryColor.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item['key'],
                    child: Text(
                      item['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            selectedItemBuilder: (context) => items
                .map(
                  (item) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      item['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _SalesReport extends StatelessWidget {
  const _SalesReport({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading.value && controller.salesRows.isEmpty) {
      return SizedBox(
        height: 360.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryGrid(controller: controller),
        SizedBox(height: 12.h),
        _SalesTable(controller: controller),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'title': 'عدد الفواتير',
        'value': controller.salesSummary['invoice_count']
      },
      {
        'title': 'الفواتير الفعالة',
        'value': controller.salesSummary['active_invoice_count'],
      },
      {
        'title': 'المبيعات',
        'value': controller.money(controller.salesSummary['gross_sales']),
      },
      {
        'title': 'النقدي',
        'value': controller.money(controller.salesSummary['cash_paid']),
      },
      {
        'title': 'على الدين',
        'value': controller.money(controller.salesSummary['debt_remaining']),
      },
      {
        'title': 'الخصومات',
        'value': controller.money(controller.salesSummary['discounts']),
      },
      {
        'title': 'الملغي',
        'value': controller.money(controller.salesSummary['cancelled_sales']),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth < 340
                ? 2
                : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: constraints.maxWidth > 700 ? 2.55 : 1.75,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor4
                    : AppColors.whiteColor2,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title'].toString(),
                    style: TextStyle(
                        fontSize: 10.5.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${item['value'] ?? 0}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.controller});

  final ReportsController controller;

  static const _columns = [
    'الرقم',
    'التاريخ',
    'الزبون',
    'الصنف',
    'الكمية',
    'الإجمالي',
    'المدفوع',
    'المتبقي',
    'الدفع',
    'الحالة',
  ];

  @override
  Widget build(BuildContext context) {
    if (controller.salesRows.isEmpty) {
      return SizedBox(
        height: 260.h,
        child: const Center(child: Text('لا يوجد بيانات')),
      );
    }

    final tableWidth = 1120.w;
    return Container(
      height: 470.h,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(6.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: .16)),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                const _SalesTableHeader(columns: _columns),
                Expanded(
                  child: ListView.separated(
                    itemCount: controller.salesRows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.primaryColor.withValues(alpha: .08),
                    ),
                    itemBuilder: (context, index) {
                      final row = controller.salesRows[index];
                      return _SalesTableRow(
                        cells: [
                          '${row['serial_number'] ?? row['id'] ?? ''}',
                          '${row['date'] ?? ''}',
                          '${row['buyer_name'] ?? ''}',
                          '${row['product_name'] ?? ''}',
                          '${row['quantity'] ?? ''}',
                          controller.money(row['total']),
                          controller.money(row['paid']),
                          controller.money(row['remaining']),
                          _paymentLabel(row['payment_type']),
                          row['status'] == 'cancelled' ? 'ملغي' : 'فعال',
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _paymentLabel(dynamic value) {
    switch (value?.toString()) {
      case 'cash':
        return 'نقدي';
      case 'debt':
        return 'على الدين';
      case 'mixed':
        return 'مختلط';
      default:
        return 'غير محدد';
    }
  }
}

class _SalesTableHeader extends StatelessWidget {
  const _SalesTableHeader({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43.h,
      color: AppColors.primaryColor,
      child: Row(
        children: columns
            .map(
              (column) => _SalesTableCell(
                text: column,
                isHeader: true,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SalesTableRow extends StatelessWidget {
  const _SalesTableRow({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: cells
            .map((cell) => _SalesTableCell(text: cell))
            .toList(growable: false),
      ),
    );
  }
}

class _SalesTableCell extends StatelessWidget {
  const _SalesTableCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112.w,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isHeader ? Colors.white : null,
              fontSize: isHeader ? 12.sp : 11.5.sp,
              fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.controller, required this.reportTitle});

  final ReportsController controller;
  final String reportTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(16.r),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          '$reportTitle قيد التجهيز',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
