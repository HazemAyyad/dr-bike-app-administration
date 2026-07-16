import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/activity_summary_model.dart';
import '../../../employee_section/data/models/logs_model.dart';
import '../../../employee_section/presentation/views/activity_log_screen.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminActivtiLogScreen extends StatefulWidget {
  const AdminActivtiLogScreen({Key? key}) : super(key: key);

  @override
  State<AdminActivtiLogScreen> createState() => _AdminActivtiLogScreenState();
}

class _AdminActivtiLogScreenState extends State<AdminActivtiLogScreen> {
  final AdminDashboardController controller =
      Get.find<AdminDashboardController>();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: controller.logsSearchQuery);
    controller.getActivitySummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'activityLog', action: false),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: controller.refreshActivityLogData,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(
                child: GetBuilder<AdminDashboardController>(
                  builder: (controller) => _ActivityLogFilters(
                    controller: controller,
                    searchController: _searchController,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(
                child: GetBuilder<AdminDashboardController>(
                  builder: (controller) => _ActivitySummarySection(
                    controller: controller,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 14.h)),
              GetBuilder<AdminDashboardController>(
                builder: (controller) {
                  if (controller.isLogsLoading.value) {
                    return const _ActivityLogSkeletonSliver();
                  }
                  if (controller.logsMap.isEmpty) {
                    return const SliverFillRemaining(child: ShowNoData());
                  }

                  final entries = _filteredLogEntries(controller);
                  if (entries.isEmpty) {
                    return const SliverFillRemaining(child: ShowNoData());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        return _ActivityDayGroup(
                          dateLabel: entry.key,
                          logs: entry.value,
                        );
                      },
                      childCount: entries.length,
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: 50.h)),
            ],
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, List<LogsModel>>> _filteredLogEntries(
    AdminDashboardController controller,
  ) {
    final query = controller.logsSearchQuery.toLowerCase();
    final selectedDate = controller.logsFilterDate;
    final selectedRange = controller.logsFilterRange;
    final filtered = <MapEntry<String, List<LogsModel>>>[];

    for (final entry in controller.logsMap.entries.take(30)) {
      final logs = entry.value.where((log) {
        final textMatches = query.isEmpty ||
            log.name.toLowerCase().contains(query) ||
            log.description.toLowerCase().contains(query) ||
            log.type.toLowerCase().contains(query);
        if (!textMatches) return false;

        final logDate = DateUtils.dateOnly(log.createdAt.toLocal());
        if (selectedDate != null) {
          return DateUtils.isSameDay(logDate, selectedDate);
        }
        if (selectedRange != null) {
          final start = DateUtils.dateOnly(selectedRange.start);
          final end = DateUtils.dateOnly(selectedRange.end);
          return !logDate.isBefore(start) && !logDate.isAfter(end);
        }
        return true;
      }).toList();

      if (logs.isNotEmpty) filtered.add(MapEntry(entry.key, logs));
    }

    return filtered;
  }
}

class _ActivityLogFilters extends StatelessWidget {
  const _ActivityLogFilters({
    required this.controller,
    required this.searchController,
  });

  final AdminDashboardController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final fillColor =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor2;
    final borderColor =
        isDark ? AppColors.customGreyColor4 : AppColors.operationalCardBorder;
    final textColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final hasDateFilters =
        controller.logsFilterDate != null || controller.logsFilterRange != null;
    final hasFilters = controller.logsSearchQuery.isNotEmpty || hasDateFilters;
    final sortLabel = controller.logsNewestFirst
        ? 'sortNewestFirst'.tr
        : 'sortOldestFirst'.tr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: controller.setLogsSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'search'.tr,
              hintStyle: const TextStyle(color: AppColors.customGreyColor5),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.customGreyColor5,
                size: 20.sp,
              ),
              suffixIcon: controller.logsSearchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        controller.setLogsSearchQuery('');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.customGreyColor5,
                        size: 18.sp,
                      ),
                    ),
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.customOrange2),
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: textColor,
                  fontSize: 13.sp,
                ),
          ),
        ),
        SizedBox(width: 8.w),
        _FilterIconButton(
          active: hasDateFilters,
          onTap: () => _showFiltersSheet(context),
        ),
        SizedBox(width: 8.w),
        _SortIconButton(
          newestFirst: controller.logsNewestFirst,
          tooltip: sortLabel,
          onTap: controller.toggleLogsSortOrder,
        ),
        if (hasFilters) ...[
          SizedBox(width: 8.w),
          _IconFilterButton(
            icon: Icons.filter_alt_off_rounded,
            onTap: () {
              searchController.clear();
              controller.clearLogsFilters();
            },
          ),
        ],
      ],
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GetBuilder<AdminDashboardController>(
          builder: (controller) {
            final isDark = ThemeService.isDark.value;
            final sheetColor =
                isDark ? AppColors.darkColor : AppColors.whiteColor;
            final borderColor = isDark
                ? AppColors.customGreyColor4
                : AppColors.operationalCardBorder;

            return Container(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _FilterButton(
                      icon: Icons.today_rounded,
                      label: controller.logsFilterDate == null
                          ? 'day'.tr
                          : _formatFilterDate(controller.logsFilterDate!),
                      active: controller.logsFilterDate != null,
                      onTap: () => _pickDate(context),
                    ),
                    SizedBox(height: 10.h),
                    _FilterButton(
                      icon: Icons.date_range_rounded,
                      label: controller.logsFilterRange == null
                          ? 'selectDateRange'.tr
                          : _formatRange(controller.logsFilterRange!),
                      active: controller.logsFilterRange != null,
                      onTap: () => _pickRange(context),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetActionButton(
                            label: 'clear'.tr,
                            icon: Icons.restart_alt_rounded,
                            isPrimary: false,
                            onTap: () {
                              controller.setLogsFilterDate(null);
                              controller.setLogsFilterRange(null);
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _SheetActionButton(
                            label: 'done'.tr,
                            icon: Icons.check_rounded,
                            isPrimary: true,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.logsFilterDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => _DatePickerTheme(child: child),
    );
    if (picked != null) {
      controller.setLogsFilterDate(DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: controller.logsFilterRange,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => _DatePickerTheme(child: child),
    );
    if (picked != null) {
      controller.setLogsFilterRange(
        DateTimeRange(
          start: DateUtils.dateOnly(picked.start),
          end: DateUtils.dateOnly(picked.end),
        ),
      );
    }
  }

  String _formatFilterDate(DateTime date) {
    final code = Get.locale?.languageCode ?? 'ar';
    return DateFormat('d/M/yyyy', code == 'ar' ? 'ar' : 'en').format(date);
  }

  String _formatRange(DateTimeRange range) {
    return '${_formatFilterDate(range.start)} - ${_formatFilterDate(range.end)}';
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background = active
        ? const Color(0xFFFFF4D6)
        : isDark
            ? AppColors.customGreyColor
            : AppColors.whiteColor2;
    final foreground = active
        ? AppColors.customOrange2
        : isDark
            ? AppColors.customGreyColor6
            : AppColors.customGreyColor5;
    final borderColor = active
        ? AppColors.customOrange3
        : isDark
            ? AppColors.customGreyColor4
            : AppColors.operationalCardBorder;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 17.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: foreground,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background = active
        ? const Color(0xFFFFF4D6)
        : isDark
            ? AppColors.customGreyColor
            : AppColors.whiteColor2;
    final foreground = active
        ? AppColors.customOrange2
        : isDark
            ? AppColors.customGreyColor6
            : AppColors.customGreyColor5;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 42.h,
          height: 42.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: foreground,
                size: 20.sp,
              ),
              if (active)
                Positioned(
                  top: 9.h,
                  right: 9.w,
                  child: Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: const BoxDecoration(
                      color: AppColors.customOrange2,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortIconButton extends StatelessWidget {
  const _SortIconButton({
    required this.newestFirst,
    required this.tooltip,
    required this.onTap,
  });

  final bool newestFirst;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor2;
    final foreground =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor5;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            width: 42.h,
            height: 42.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.sort_rounded,
                  color: foreground,
                  size: 20.sp,
                ),
                Positioned(
                  right: 8.w,
                  bottom: 8.h,
                  child: Icon(
                    newestFirst
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.customOrange2,
                    size: 15.sp,
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

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background = isPrimary
        ? AppColors.customOrange3
        : isDark
            ? AppColors.customGreyColor
            : AppColors.whiteColor2;
    final foreground = isPrimary
        ? AppColors.secondaryColor
        : isDark
            ? AppColors.customGreyColor6
            : AppColors.secondaryColor;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          height: 40.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 17.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: foreground,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTheme extends StatelessWidget {
  const _DatePickerTheme({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final base = Theme.of(context);
    final surface = isDark ? AppColors.darkColor : AppColors.whiteColor;
    final onSurface = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final secondarySurface =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor2;

    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.customOrange3,
          onPrimary: AppColors.secondaryColor,
          primaryContainer: const Color(0xFFFFF4D6),
          onPrimaryContainer: AppColors.secondaryColor,
          surface: surface,
          onSurface: onSurface,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: surface,
          headerBackgroundColor: secondarySurface,
          headerForegroundColor: onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.customOrange2,
            textStyle: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _IconFilterButton extends StatelessWidget {
  const _IconFilterButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.redColor.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 38.h,
          height: 38.h,
          child: Icon(
            icon,
            color: AppColors.redColor,
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _ActivitySummarySection extends StatelessWidget {
  const _ActivitySummarySection({required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isActivitySummaryLoading.value &&
        controller.activitySummaryModel == null) {
      return const _ActivitySummarySkeleton();
    }

    final summary = controller.activitySummaryModel;
    if (summary == null) return const SizedBox.shrink();

    final totals = summary.totals;
    final metrics = [
      _MetricData(
        icon: Icons.receipt_long_rounded,
        label: 'الفواتير',
        value: totals.invoicesCount.toString(),
      ),
      _MetricData(
        icon: Icons.groups_rounded,
        label: 'الزباين',
        value: totals.customersCount.toString(),
      ),
      _MetricData(
        icon: Icons.point_of_sale_rounded,
        label: 'المبيعات',
        value: _formatMoney(totals.salesAmount),
      ),
      _MetricData(
        icon: Icons.payments_rounded,
        label: 'المدفوع',
        value: _formatMoney(totals.paidAmount),
      ),
      _MetricData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'المتبقي',
        value: _formatMoney(totals.remainingAmount),
      ),
      _MetricData(
        icon: Icons.handshake_rounded,
        label: 'قيود الدين',
        value: totals.debtTransactionsCount.toString(),
        subValue: _formatMoney(totals.debtAmount),
      ),
      _MetricData(
        icon: Icons.inventory_2_rounded,
        label: 'كمية مباعة',
        value: _formatQuantity(totals.soldItemsQuantity),
      ),
      _MetricData(
        icon: Icons.category_rounded,
        label: 'أنواع النشاط',
        value: totals.logTypesCount.toString(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: metrics.map((metric) => _SummaryMetric(metric)).toList(),
        ),
        SizedBox(height: 12.h),
        _SummaryList<ActivityTypeCountModel>(
          title: 'أنواع النشاط',
          icon: Icons.view_list_rounded,
          items: summary.logTypeCounts,
          emptyText: 'لا يوجد نشاط',
          itemBuilder: (item) => _SummaryLine(
            title: item.type,
            value: item.count.toString(),
          ),
        ),
        SizedBox(height: 8.h),
        _SummaryList<ActivityDebtPersonModel>(
          title: 'تقرير الديون',
          icon: Icons.account_balance_rounded,
          items: summary.debtPeople,
          emptyText: 'لا توجد ديون ضمن الفلتر',
          itemBuilder: (item) => _SummaryLine(
            title: item.name,
            value: _formatMoney(item.amount),
            subtitle:
                '${item.transactionsCount} حركة | لنا ${_formatMoney(item.givenAmount)} | علينا ${_formatMoney(item.takenAmount)}',
          ),
        ),
        SizedBox(height: 8.h),
        _SummaryList<ActivitySalesPersonModel>(
          title: 'تقرير المبيعات',
          icon: Icons.shopping_bag_rounded,
          items: summary.salesPeople,
          emptyText: 'لا توجد مبيعات ضمن الفلتر',
          itemBuilder: (item) => _SummaryLine(
            title: item.name,
            value: _formatMoney(item.salesAmount),
            subtitle:
                '${item.invoicesCount} فاتورة | مدفوع ${_formatMoney(item.paidAmount)} | متبقي ${_formatMoney(item.remainingAmount)}',
          ),
        ),
        SizedBox(height: 8.h),
        _SummaryList<ActivitySoldProductModel>(
          title: 'المنتجات المباعة',
          icon: Icons.inventory_rounded,
          items: summary.soldProducts,
          emptyText: 'لا توجد منتجات مباعة ضمن الفلتر',
          itemBuilder: (item) => _SummaryLine(
            title: item.name,
            value: _formatQuantity(item.quantity),
            subtitle:
                '${item.linesCount} سطر | ${_formatMoney(item.salesAmount)}',
          ),
        ),
      ],
    );
  }

  static String _formatMoney(double value) {
    final code = Get.locale?.languageCode ?? 'ar';
    return NumberFormat.decimalPattern(code == 'ar' ? 'ar' : 'en')
        .format(value);
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(this.metric);

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor;
    final borderColor =
        isDark ? AppColors.customGreyColor4 : AppColors.operationalCardBorder;
    final titleColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final bodyColor =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor5;

    return Container(
      width: 0.43.sw,
      constraints: BoxConstraints(minHeight: 70.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: AppColors.customOrange2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              metric.icon,
              color: AppColors.customOrange2,
              size: 17.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: bodyColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: titleColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (metric.subValue != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    metric.subValue!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: bodyColor,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryList<T> extends StatelessWidget {
  const _SummaryList({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
  });

  final String title;
  final IconData icon;
  final List<T> items;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor;
    final borderColor =
        isDark ? AppColors.customGreyColor4 : AppColors.operationalCardBorder;
    final titleColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final bodyColor =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor5;

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
          childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 9.h),
          initiallyExpanded: false,
          iconColor: AppColors.primaryColor,
          collapsedIconColor: AppColors.primaryColor,
          title: Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 17.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: titleColor,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  items.length.toString(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          children: [
            if (items.isEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: bodyColor,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else
              ...items.take(5).map((item) => itemBuilder(item)),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final bodyColor =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor5;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: titleColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: bodyColor,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.customOrange2,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummarySkeleton extends StatelessWidget {
  const _ActivitySummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(
        4,
        (_) => _SkeletonBox(width: 0.43.sw, height: 70.h),
      ),
    );
  }
}

class _ActivityDayGroup extends StatelessWidget {
  const _ActivityDayGroup({
    required this.dateLabel,
    required this.logs,
  });

  final String dateLabel;
  final List<dynamic> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateHeader(dateLabel: dateLabel, count: logs.length),
          SizedBox(height: 8.h),
          ...logs.map((log) => _ActivityLogCard(log: log)),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.dateLabel,
    required this.count,
  });

  final String dateLabel;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.isDark.value
        ? AppColors.whiteColor
        : AppColors.secondaryColor;
    final accentColor = ThemeService.isDark.value
        ? AppColors.customOrange3
        : AppColors.customOrange2;
    final accentBackground = ThemeService.isDark.value
        ? AppColors.customGreyColor4
        : const Color(0xFFFFF4D6);

    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: accentBackground,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            color: accentColor,
            size: 17.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            dateLabel,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: accentBackground,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
          ),
        ),
      ],
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log});

  final dynamic log;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final background =
        isDark ? AppColors.customGreyColor : AppColors.whiteColor;
    final borderColor =
        isDark ? AppColors.customGreyColor4 : AppColors.operationalCardBorder;
    final titleColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final bodyColor =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor5;
    final timeText = _formatLogTime(log.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () => Get.dialog(ShowLogDetails(log: log)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.primaryColor,
                    size: 15.sp,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5.sp,
                            ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        log.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 10.5.sp,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.customGreyColor4
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: bodyColor,
                        size: 11.sp,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        timeText,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5.sp,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLogTime(DateTime dateTime) {
    final code = Get.locale?.languageCode ?? 'ar';
    return DateFormat('hh:mm a', code == 'ar' ? 'ar' : 'en')
        .format(dateTime.toLocal());
  }
}

class _ActivityLogSkeletonSliver extends StatelessWidget {
  const _ActivityLogSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final showHeader = index == 0 || index == 4;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader) ...[
                  _SkeletonBox(width: 150.w, height: 18.h),
                  SizedBox(height: 10.h),
                ],
                const _SkeletonLogCard(),
              ],
            ),
          );
        },
        childCount: 8,
      ),
    );
  }
}

class _SkeletonLogCard extends StatelessWidget {
  const _SkeletonLogCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        border: Border.all(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.operationalCardBorder,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 26.w, height: 26.w),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 11.h),
                SizedBox(height: 5.h),
                _SkeletonBox(width: double.infinity, height: 9.h),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _SkeletonBox(width: 64.w, height: 22.h),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final baseColor = ThemeService.isDark.value
        ? AppColors.customGreyColor4
        : AppColors.whiteColor2;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.45, end: 0.85),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}
