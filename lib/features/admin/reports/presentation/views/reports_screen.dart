import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
        builder: (_) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportsRail(controller: controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadSalesReport,
                child: ListView(
                  padding: EdgeInsets.all(20.r),
                  children: [
                    _FiltersBar(controller: controller),
                    SizedBox(height: 14.h),
                    if (controller.selectedReport.value == 'sales')
                      _SalesReport(controller: controller)
                    else
                      _ComingSoon(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsRail extends StatelessWidget {
  const _ReportsRail({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245.w,
      height: double.infinity,
      padding: EdgeInsets.all(12.r),
      color: ThemeService.isDark.value
          ? AppColors.customGreyColor
          : AppColors.whiteColor2,
      child: ListView.separated(
        itemCount: controller.reports.length,
        separatorBuilder: (_, __) => SizedBox(height: 7.h),
        itemBuilder: (context, index) {
          final report = controller.reports[index];
          final selected = controller.selectedReport.value == report['key'];
          return InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () => controller.selectReport(report['key']!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 19.sp,
                    color: selected ? Colors.white : AppColors.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      report['title']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : null,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
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
          OutlinedButton.icon(
            onPressed: () => controller.pickCustomRange(context),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              controller.fromDate == null || controller.toDate == null
                  ? 'اختيار الفترة'
                  : '${_date(controller.fromDate!)} - ${_date(controller.toDate!)}',
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

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<Map<String, String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item['key'],
                  child: Text(item['title']!),
                ),
              )
              .toList(growable: false),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
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
        SizedBox(height: 14.h),
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
        final columns = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 9.w,
            mainAxisSpacing: 9.h,
            childAspectRatio: 2.9,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title'].toString(),
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '${item['value'] ?? 0}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 18.sp,
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

  @override
  Widget build(BuildContext context) {
    if (controller.salesRows.isEmpty) {
      return SizedBox(
        height: 260.h,
        child: const Center(child: Text('لا يوجد بيانات')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(AppColors.primaryColor),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          columns: const [
            DataColumn(label: Text('الرقم')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('الزبون')),
            DataColumn(label: Text('الصنف')),
            DataColumn(label: Text('الكمية')),
            DataColumn(label: Text('الإجمالي')),
            DataColumn(label: Text('المدفوع')),
            DataColumn(label: Text('المتبقي')),
            DataColumn(label: Text('الدفع')),
            DataColumn(label: Text('الحالة')),
          ],
          rows: controller.salesRows.map((row) {
            return DataRow(
              cells: [
                DataCell(Text('${row['serial_number'] ?? row['id'] ?? ''}')),
                DataCell(Text('${row['date'] ?? ''}')),
                DataCell(Text('${row['buyer_name'] ?? ''}')),
                DataCell(Text('${row['product_name'] ?? ''}')),
                DataCell(Text('${row['quantity'] ?? ''}')),
                DataCell(Text(controller.money(row['total']))),
                DataCell(Text(controller.money(row['paid']))),
                DataCell(Text(controller.money(row['remaining']))),
                DataCell(Text(_paymentLabel(row['payment_type']))),
                DataCell(Text(row['status'] == 'cancelled' ? 'ملغي' : 'فعال')),
              ],
            );
          }).toList(growable: false),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final report = controller.reports.firstWhere(
      (item) => item['key'] == controller.selectedReport.value,
      orElse: () => controller.reports.first,
    );
    return Container(
      height: 260.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '${report['title']} قيد التجهيز',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
      ),
    );
  }
}
