import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
                  enabled: true,
                  onTap: () async {
                    await controller.openReport(report['key']!);
                    await Get.toNamed(
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
        return;
      }
      if (!controller.hasLoadedCurrentReport && !controller.isLoading.value) {
        controller.loadCurrentReport();
      }
      if (reportKey == 'statement' &&
          controller.selectedPersonId.value.isEmpty &&
          !controller.didPromptStatementFilter) {
        controller.didPromptStatementFilter = true;
        _showFiltersSheet(context, controller);
      }
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        action: false,
        actions: [
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
          IconButton(
            tooltip: 'PDF',
            onPressed: () => _downloadReportPdf(title, controller),
            icon: Icon(
              Icons.file_download_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
          ),
          IconButton(
            tooltip: 'مشاركة PDF',
            onPressed: () => _shareReportPdf(title, controller),
            icon: Icon(
              Icons.ios_share_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
          ),
          IconButton(
            tooltip: 'طباعة',
            onPressed: () => _printReport(title, controller),
            icon: Icon(
              Icons.print_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
          ),
        ],
      ),
      body: GetBuilder<ReportsController>(
        builder: (_) {
          return RefreshIndicator(
            onRefresh: controller.loadCurrentReport,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _ReportContent(controller: controller),
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
                  await controller.loadCurrentReport();
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
          if (controller.selectedReport.value == 'sales') ...[
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
          if (controller.selectedReport.value == 'checks') ...[
            _FilterField(
              label: 'نوع الشيك',
              child: _DropdownChip(
                value: controller.selectedCheckDirection.value,
                items: controller.checkDirections,
                onChanged: controller.selectCheckDirection,
                fullWidth: true,
              ),
            ),
          ],
          if (controller.selectedReport.value == 'statement') ...[
            _FilterField(
              label: 'نوع الحساب',
              child: _DropdownChip(
                value: controller.selectedPersonType.value,
                items: controller.personTypes,
                onChanged: controller.selectPersonType,
                fullWidth: true,
              ),
            ),
            SizedBox(height: 10.h),
            _FilterField(
              label: 'الحساب',
              child: _PersonSearchField(
                controller: controller,
                fullWidth: true,
              ),
            ),
          ],
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
        if (controller.selectedReport.value == 'sales') ...[
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
        ],
        if (controller.selectedReport.value == 'checks')
          _DropdownChip(
            value: controller.selectedCheckDirection.value,
            items: controller.checkDirections,
            onChanged: controller.selectCheckDirection,
          ),
        if (controller.selectedReport.value == 'statement') ...[
          _DropdownChip(
            value: controller.selectedPersonType.value,
            items: controller.personTypes,
            onChanged: controller.selectPersonType,
          ),
          _PersonSearchField(controller: controller),
        ],
        IconButton.filledTonal(
          tooltip: 'تطبيق',
          onPressed: controller.loadCurrentReport,
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

class _PersonSearchField extends StatelessWidget {
  const _PersonSearchField({
    required this.controller,
    this.fullWidth = false,
  });

  final ReportsController controller;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final selected = controller.personItems().firstWhere(
          (item) => item['key'] == controller.selectedPersonId.value,
          orElse: () => {'key': '', 'title': 'اختر الحساب'},
        );

    return ConstrainedBox(
      constraints: fullWidth
          ? const BoxConstraints(minWidth: double.infinity)
          : BoxConstraints(minWidth: 128.w, maxWidth: 220.w),
      child: OutlinedButton.icon(
        onPressed: () => _showPersonSearchSheet(context, controller),
        icon: const Icon(Icons.person_search_outlined),
        label: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            selected['title'] ?? 'اختر الحساب',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

void _showPersonSearchSheet(
  BuildContext context,
  ReportsController controller,
) {
  final searchController = TextEditingController();
  Get.bottomSheet(
    StatefulBuilder(
      builder: (context, setState) {
        final query = searchController.text.trim().toLowerCase();
        final people = controller.personItems().where((item) {
          if ((item['key'] ?? '').isEmpty) return false;
          if (query.isEmpty) return true;
          return (item['title'] ?? '').toLowerCase().contains(query);
        }).toList(growable: false);

        return Container(
          height: MediaQuery.of(context).size.height * .78,
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_search_outlined,
                        color: AppColors.primaryColor),
                    SizedBox(width: 8.w),
                    Text(
                      'اختيار الحساب',
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
                SizedBox(height: 10.h),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'ابحث بالاسم أو الهاتف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: people.isEmpty
                      ? const Center(child: Text('لا يوجد نتائج'))
                      : ListView.separated(
                          itemCount: people.length,
                          separatorBuilder: (_, __) => Divider(height: 1.h),
                          itemBuilder: (context, index) {
                            final person = people[index];
                            final selected = person['key'] ==
                                controller.selectedPersonId.value;
                            return ListTile(
                              dense: true,
                              selected: selected,
                              leading: Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.person_outline,
                                color: selected ? AppColors.primaryColor : null,
                              ),
                              title: Text(
                                person['title'] ?? '',
                                maxLines: 2,
                              ),
                              onTap: () {
                                controller.selectPerson(person['key'] ?? '');
                                Get.back();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    isScrollControlled: true,
  );
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading.value && controller.activeRows().isEmpty) {
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
        _ReportTable(controller: controller),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cards = controller.activeSummaryCards();

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

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.activeRows();
    final columns = controller.activeColumns();

    if (rows.isEmpty) {
      return SizedBox(
        height: 260.h,
        child: const Center(child: Text('لا يوجد بيانات')),
      );
    }

    final tableWidth = columns.length * _SalesTableCell.cellWidth();
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
                _SalesTableHeader(columns: columns),
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.primaryColor.withValues(alpha: .08),
                    ),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return _SalesTableRow(
                        cells: controller.cellsForRow(row),
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
}

class _SalesTableHeader extends StatelessWidget {
  const _SalesTableHeader({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 43.h),
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
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 44.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells
              .map((cell) => _SalesTableCell(text: cell))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SalesTableCell extends StatelessWidget {
  const _SalesTableCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  static double cellWidth() => 96.w;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellWidth(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(
              color: isHeader ? Colors.white : null,
              fontSize: isHeader ? 10.5.sp : 10.sp,
              fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _downloadReportPdf(
  String title,
  ReportsController controller,
) async {
  final bytes = await _ReportsPdfBuilder.build(title, controller);
  final dir = await _reportsDownloadDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final fileName = _reportFileName(controller.selectedReport.value);
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  Get.snackbar('PDF', 'تم تنزيل التقرير: $fileName');
  await OpenFilex.open(file.path);
}

Future<void> _shareReportPdf(
  String title,
  ReportsController controller,
) async {
  final bytes = await _ReportsPdfBuilder.build(title, controller);
  await Printing.sharePdf(
    bytes: bytes,
    filename: '${controller.selectedReport.value}_report.pdf',
  );
}

Future<Directory> _reportsDownloadDirectory() async {
  final downloads = await getDownloadsDirectory();
  if (downloads != null) return downloads;

  if (Platform.isAndroid) {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
  }

  return getApplicationDocumentsDirectory();
}

String _reportFileName(String key) {
  final now = DateTime.now();
  final stamp =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  return '${key}_report_$stamp.pdf';
}

Future<void> _printReport(
  String title,
  ReportsController controller,
) async {
  final bytes = await _ReportsPdfBuilder.build(title, controller);
  await Printing.layoutPdf(
    name: '${controller.selectedReport.value}_report.pdf',
    onLayout: (_) async => bytes,
  );
}

class _ReportsPdfBuilder {
  static final PdfColor _brandColor = PdfColor.fromHex('#6B65BD');
  static final PdfColor _borderColor = PdfColor.fromHex('#D1D5DB');
  static final PdfColor _textColor = PdfColor.fromHex('#111827');
  static final PdfColor _mutedColor = PdfColor.fromHex('#6B7280');
  static final PdfColor _rowColor = PdfColor.fromHex('#F9FAFB');

  static Future<Uint8List> build(
    String title,
    ReportsController controller,
  ) async {
    final regularData =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    final boldData =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final logo = await _logo();
    final doc = pw.Document();
    final columns = controller.activeColumns();
    final rows = controller.activeRows();
    final summary = controller.activeSummaryCards().isEmpty
        ? [
            {'title': 'عدد السجلات', 'value': rows.length}
          ]
        : controller.activeSummaryCards();
    final from = controller.reportPeriod['from_date']?.toString() ?? '-';
    final to = controller.reportPeriod['to_date']?.toString() ?? '-';
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(
            font: regular,
            fontSize: 11,
            color: _textColor,
          ),
        ),
        footer: (context) => _reportFooter(
          context: context,
          generatedAt: generatedAt,
        ),
        build: (_) => [
          _reportHeader(
            title: title,
            from: from,
            to: to,
            logo: logo,
            bold: bold,
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 10, bottom: 10),
            height: 1.3,
            color: _brandColor,
          ),
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 8),
          _reportMetaBox(
            bold: bold,
            title: title,
            from: from,
            to: to,
            generatedAt: generatedAt,
            recordsCount: rows.length,
          ),
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('ملخص التقرير', bold),
            pw.SizedBox(height: 4),
            _summaryCards(summary, bold: bold),
          ],
          pw.SizedBox(height: 12),
          _sectionTitle('تفاصيل التقرير', bold),
          pw.SizedBox(height: 4),
          if (rows.isEmpty)
            _emptyState()
          else
            _reportDataTable(
              headers: columns.isEmpty ? const ['البيان'] : columns,
              data: rows
                  .map(controller.cellsForRow)
                  .map((row) => row.reversed.toList(growable: false))
                  .toList(growable: false),
              bold: bold,
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data =
          await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _reportHeader({
    required String title,
    required String from,
    required String to,
    required pw.MemoryImage? logo,
    required pw.Font bold,
  }) {
    final qrPayload = [
      'Doctor Bike Report',
      title,
      '$from - $to',
    ].join('\n');

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 130,
            height: 88,
            child: logo == null
                ? pw.SizedBox()
                : pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, height: 88),
                  ),
          ),
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload,
                  width: 64,
                  height: 64,
                  drawText: false,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '$from - $to',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontSize: 8, color: _mutedColor),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'دكتور بايك - تقرير محاسبي',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 21,
                  color: _brandColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _reportMetaBox({
    required pw.Font bold,
    required String title,
    required String from,
    required String to,
    required DateTime generatedAt,
    required int recordsCount,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.FlexColumnWidth(),
          },
          children: [
            _metaRow(
              left: _metaLine(
                'تاريخ الطباعة',
                DateFormat('yyyy-MM-dd HH:mm').format(generatedAt),
                bold,
                valueLtr: true,
              ),
              right: _metaLine('اسم التقرير', title, bold),
            ),
            _metaRow(
              left: _metaLine('إلى تاريخ', to, bold, valueLtr: true),
              right: _metaLine('من تاريخ', from, bold, valueLtr: true),
            ),
            _metaRow(
              left: _metaLine('النظام', 'دكتور بايك', bold),
              right: _metaLine('عدد السجلات', '$recordsCount', bold,
                  valueLtr: true),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _metaRow({
    required pw.Widget left,
    required pw.Widget right,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(right: 16, bottom: 5),
          child: left,
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 5),
          child: right,
        ),
      ],
    );
  }

  static pw.Widget _metaLine(
    String label,
    String value,
    pw.Font bold, {
    bool valueLtr = false,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label:', style: pw.TextStyle(font: bold)),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Text(
              value,
              textDirection:
                  valueLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: PdfColor.fromHex('#374151')),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards(
    List<Map<String, dynamic>> summary, {
    required pw.Font bold,
  }) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: summary
          .map(
            (item) => pw.Container(
              width: 142,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderColor, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    color: _brandColor,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      item['title']?.toString() ?? '',
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 9.5,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Container(
                    color: _rowColor,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: pw.Text(
                      item['value']?.toString() ?? '0',
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: bold, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _reportDataTable({
    required List<String> headers,
    required List<List<String>> data,
    required pw.Font bold,
  }) {
    final reversedHeaders = headers.reversed.toList(growable: false);
    return pw.TableHelper.fromTextArray(
      headers: reversedHeaders,
      data: data,
      tableDirection: pw.TextDirection.ltr,
      headerDirection: pw.TextDirection.rtl,
      border: pw.TableBorder.all(color: _borderColor, width: 0.8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      headerStyle: pw.TextStyle(
        font: bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _brandColor),
      oddRowDecoration: pw.BoxDecoration(color: _rowColor),
      headerAlignments: {
        for (var i = 0; i < reversedHeaders.length; i++) i: pw.Alignment.center,
      },
      cellBuilder: (index, value, rowNum) {
        final text = value.toString();
        final isArabic = _containsArabic(text);
        return pw.Text(
          text,
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8.5),
        );
      },
    );
  }

  static pw.Widget _emptyState() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 18),
      decoration: pw.BoxDecoration(
        color: _rowColor,
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Text(
        'لا يوجد بيانات ضمن الفترة المحددة',
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: _mutedColor),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: bold, fontSize: 12),
      ),
    );
  }

  static pw.Widget _reportFooter({
    required pw.Context context,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor)),
      ),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(
          children: [
            pw.Text(
              DateFormat('yyyy-MM-dd HH:mm').format(generatedAt),
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(fontSize: 9, color: _mutedColor),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(fontSize: 9, color: _mutedColor),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                'هذه نسخة مطبوعة من تقرير نظام دكتور بايك تم إنشاؤها بتاريخ',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 9, color: _mutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _containsArabic(String value) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
