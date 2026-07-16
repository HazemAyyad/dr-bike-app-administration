import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../../../maintenance/domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../../maintenance/presentation/widgets/maintenance_invoice_sheet.dart';
import '../../../sales/data/datasources/sales_datasources.dart';
import '../../../sales/data/models/daily_session_model.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';
import '../controllers/boxes_controller.dart';
import '../controllers/boxes_serves.dart';
import '../widgets/transfer_balance_widget.dart';

class DailyBoxesScreen extends StatefulWidget {
  const DailyBoxesScreen({Key? key}) : super(key: key);

  @override
  State<DailyBoxesScreen> createState() => _DailyBoxesScreenState();
}

class _DailyBoxesScreenState extends State<DailyBoxesScreen> {
  final BoxesController controller = Get.find<BoxesController>();
  String _filter = 'all';
  List<DailySessionSummaryModel> _salesSessions = const [];
  bool _loadingSalesSessions = false;
  _DailyBoxLogScope _salesSessionScope = _DailyBoxLogScope.today;
  DateTime? _salesSessionCustomDate;

  @override
  void initState() {
    super.initState();
    _loadSalesSessions();
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadSalesSessions() async {
    setState(() => _loadingSalesSessions = true);
    try {
      AppDependencyRegistry.ensureSales();
      final ds = Get.find<SalesDatasource>();
      final today = _dateOnly(DateTime.now());
      String? fromDate;
      String? toDate;
      switch (_salesSessionScope) {
        case _DailyBoxLogScope.today:
          fromDate = _apiDate(today);
          toDate = fromDate;
          break;
        case _DailyBoxLogScope.yesterday:
          final target = today.subtract(const Duration(days: 1));
          fromDate = _apiDate(target);
          toDate = fromDate;
          break;
        case _DailyBoxLogScope.custom:
          final target = _salesSessionCustomDate == null
              ? today
              : _dateOnly(_salesSessionCustomDate!);
          fromDate = _apiDate(target);
          toDate = fromDate;
          break;
        case _DailyBoxLogScope.all:
          break;
      }
      final sessions = await ds.getDailySessionsHistory(
        fromDate: fromDate,
        toDate: toDate,
      );
      if (!mounted) return;
      setState(() => _salesSessions = sessions);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salesSessions = const []);
    } finally {
      if (mounted) setState(() => _loadingSalesSessions = false);
    }
  }

  List<ShownBoxesModel> _dailyBoxes() {
    final Map<int, ShownBoxesModel> unique = {};
    for (final box in [
      ...BoxesServes().shownBoxes,
      ...BoxesServes().shownBoxesArchive,
    ]) {
      if (_isDailyBox(box)) unique[box.boxId] = box;
    }

    final boxes = unique.values.where((box) {
      if (_filter == 'all') return true;
      return _boxKind(box) == _filter;
    }).toList();

    boxes.sort((a, b) => _boxKindOrder(a).compareTo(_boxKindOrder(b)));
    return boxes;
  }

  bool _isDailyBox(ShownBoxesModel box) {
    final type = box.type.toLowerCase();
    final name = box.boxName.toLowerCase();
    if (type == 'daily_sales') {
      return false;
    }

    return type == 'daily_maintenance' ||
        type.contains('daily_order') ||
        type.contains('sales_order') ||
        name.contains('صندوق الصيانة اليومي') ||
        name.contains('صندوق الطلبيات اليومي') ||
        name.contains('صندوق الطلبات اليومي');
  }

  String _boxKind(ShownBoxesModel box) {
    final type = box.type.toLowerCase();
    final name = box.boxName.toLowerCase();
    if (type.contains('maintenance') || name.contains('الصيانة')) {
      return 'maintenance';
    }
    if (type.contains('order') ||
        name.contains('الطلبيات') ||
        name.contains('طلبات')) {
      return 'orders';
    }
    return 'sales';
  }

  int _boxKindOrder(ShownBoxesModel box) {
    switch (_boxKind(box)) {
      case 'sales':
        return 1;
      case 'orders':
        return 2;
      case 'maintenance':
        return 3;
      default:
        return 4;
    }
  }

  List<BoxLogModel> _boxLogs(ShownBoxesModel box) {
    final id = box.boxId.toString();
    final logs = BoxesServes().allBoxesLogs.where((log) {
      return log.boxId == id || log.fromBoxId == id || log.toBoxId == id;
    }).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  String _amount(double value) => NumberFormat('#,##0.##').format(value);

  String _date(DateTime date) {
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat('d/M/yyyy hh:mm a', locale).format(date.toLocal());
  }

  Future<void> _pickSalesSessionDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _salesSessionCustomDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _salesSessionCustomDate = picked;
      _salesSessionScope = _DailyBoxLogScope.custom;
    });
    await _loadSalesSessions();
  }

  Future<void> _showSalesSessionDetails(
    BuildContext context,
    DailySessionSummaryModel session,
  ) async {
    AppDependencyRegistry.ensureSales();
    final ds = Get.find<SalesDatasource>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          minChildSize: .45,
          maxChildSize: .95,
          builder: (context, scrollController) {
            return FutureBuilder<DailySessionDetailModel>(
              future: ds.getDailySessionDetail(session.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('noData'.tr));
                }
                return _SalesSessionDetailSheet(
                  detail: snapshot.data!,
                  amount: _amount,
                  dateText: _dateText,
                  scrollController: scrollController,
                );
              },
            );
          },
        );
      },
    );
  }

  String _dateText(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return _date(parsed);
  }

  String _kindLabel(ShownBoxesModel box) {
    switch (_boxKind(box)) {
      case 'maintenance':
        return 'dailyBoxMaintenance'.tr;
      case 'orders':
        return 'dailyBoxOrders'.tr;
      default:
        return 'dailyBoxSales'.tr;
    }
  }

  Color _kindColor(ShownBoxesModel box) {
    switch (_boxKind(box)) {
      case 'maintenance':
        return const Color(0xFF007C89);
      case 'orders':
        return const Color(0xFF8A6F02);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Future<void> _openMaintenanceInvoice(
    BuildContext context,
    BoxLogModel log,
  ) async {
    final maintenanceId = log.maintenanceId?.trim();
    if (maintenanceId == null || maintenanceId.isEmpty) return;

    final result = await GetMaintenanceInvoiceUsecase(
      maintenanceRepository: Get.find<MaintenanceImplement>(),
    ).call(maintenanceId: maintenanceId);

    if (!mounted) return;

    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      ),
      (invoice) => showMaintenanceInvoiceSheet(context, invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = ThemeService.isDark.value
        ? AppColors.darkColor
        : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: background,
      appBar: CustomAppBar(
        title: 'dailyBoxes',
        action: false,
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: () => controller.getAllBoxes(showLoading: true),
            icon: const Icon(Icons.refresh),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        final boxes = _dailyBoxes();
        final showSalesSessions = _filter == 'all' || _filter == 'sales';
        final hasSalesSessions = showSalesSessions && _salesSessions.isNotEmpty;
        if ((controller.isLoading.value || _loadingSalesSessions) &&
            boxes.isEmpty &&
            !hasSalesSessions) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.pullToRefresh(),
              _loadSalesSessions(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              _FilterBar(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              SizedBox(height: 12.h),
              if (showSalesSessions)
                _SalesSessionsSection(
                  sessions: _salesSessions,
                  loading: _loadingSalesSessions,
                  scope: _salesSessionScope,
                  customDate: _salesSessionCustomDate,
                  amount: _amount,
                  dateText: _dateText,
                  onScopeChanged: (scope) async {
                    setState(() => _salesSessionScope = scope);
                    await _loadSalesSessions();
                  },
                  onPickDate: () => _pickSalesSessionDate(context),
                  onOpenDetails: (session) =>
                      _showSalesSessionDetails(context, session),
                ),
              if (showSalesSessions && boxes.isNotEmpty) SizedBox(height: 12.h),
              if (boxes.isEmpty && !hasSalesSessions)
                SizedBox(height: 360.h, child: const ShowNoData())
              else
                ...boxes.map((box) => _DailyBoxCard(
                      box: box,
                      logs: _boxLogs(box),
                      amount: _amount,
                      date: _date,
                      kindLabel: _kindLabel(box),
                      kindColor: _kindColor(box),
                      onTransfer: () {
                        controller.transferToBoxIdController.clear();
                        controller.transferTotalController.clear();
                        Get.dialog(
                          TransferBalanceWidget(
                            boxId: box.boxId,
                            currency: box.currency,
                          ),
                        );
                      },
                      onOpenInvoice: (log) =>
                          _openMaintenanceInvoice(context, log),
                    )),
            ],
          ),
        );
      }),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <String, String>{
      'all': 'allDailyBoxes'.tr,
      'sales': 'dailyBoxSales'.tr,
      'orders': 'dailyBoxOrders'.tr,
      'maintenance': 'dailyBoxMaintenance'.tr,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = value == entry.key;
          return Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: AppColors.secondaryColor,
              labelStyle: TextStyle(
                color:
                    selected ? AppColors.whiteColor : AppColors.secondaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: AppColors.whiteColor,
              side: BorderSide(
                color: selected
                    ? AppColors.secondaryColor
                    : AppColors.operationalCardBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SalesSessionsSection extends StatelessWidget {
  const _SalesSessionsSection({
    required this.sessions,
    required this.loading,
    required this.scope,
    required this.customDate,
    required this.amount,
    required this.dateText,
    required this.onScopeChanged,
    required this.onPickDate,
    required this.onOpenDetails,
  });

  final List<DailySessionSummaryModel> sessions;
  final bool loading;
  final _DailyBoxLogScope scope;
  final DateTime? customDate;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final ValueChanged<_DailyBoxLogScope> onScopeChanged;
  final VoidCallback onPickDate;
  final ValueChanged<DailySessionSummaryModel> onOpenDetails;

  Map<String, List<DailySessionSummaryModel>> _groupByDay() {
    final groups = <String, List<DailySessionSummaryModel>>{};
    for (final session in sessions) {
      groups
          .putIfAbsent(session.businessDate, () => <DailySessionSummaryModel>[])
          .add(session);
    }
    return groups;
  }

  String _dayTitle(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    if (current == today) return 'today'.tr;
    if (current == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr;
    }
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat('EEEE d/M/yyyy', locale).format(current);
  }

  Map<String, double> _salesTotalsByCurrency(
    Iterable<DailySessionSummaryModel> rows,
  ) {
    final totals = <String, double>{};
    for (final session in rows) {
      for (final row in session.currencies) {
        totals[row.currency] = (totals[row.currency] ?? 0) + row.salesCollected;
      }
    }
    return totals;
  }

  String _totalsText(Map<String, double> totals) {
    if (totals.isEmpty) return amount(0);
    return totals.entries
        .map((entry) => '${amount(entry.value)} ${entry.key}')
        .join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.isDark.value
        ? AppColors.whiteColor
        : AppColors.secondaryColor;
    final cardColor = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : AppColors.whiteColor;
    final grouped = _groupByDay();
    final allTotal = _totalsText(_salesTotalsByCurrency(sessions));

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.operationalCardBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.all(12.w),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          leading: Icon(
            Icons.point_of_sale_outlined,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
          title: Text(
            'salesDailyHistoryTitle'.tr,
            style: TextStyle(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${'salesDailySalesCollected'.tr}: $allTotal',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: loading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          children: [
            _DailyBoxLogFilterBar(
              scope: scope,
              customDate: customDate,
              onChanged: onScopeChanged,
              onPickDate: onPickDate,
            ),
            SizedBox(height: 10.h),
            if (!loading && sessions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  'noData'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.greyColor, fontSize: 12.sp),
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => _SalesDayGroup(
                  title: _dayTitle(entry.key),
                  sessions: entry.value,
                  totalText: _totalsText(_salesTotalsByCurrency(entry.value)),
                  amount: amount,
                  dateText: dateText,
                  onOpenDetails: onOpenDetails,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SalesDayGroup extends StatelessWidget {
  const _SalesDayGroup({
    required this.title,
    required this.sessions,
    required this.totalText,
    required this.amount,
    required this.dateText,
    required this.onOpenDetails,
  });

  final String title;
  final List<DailySessionSummaryModel> sessions;
  final String totalText;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final ValueChanged<DailySessionSummaryModel> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
        title: Text(
          title,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${'salesDailySalesCollected'.tr}: $totalText',
          style: TextStyle(
            color: AppColors.greyColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: sessions
            .map(
              (session) => _SalesSessionTile(
                session: session,
                amount: amount,
                dateText: dateText,
                onOpenDetails: () => onOpenDetails(session),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SalesSessionTile extends StatelessWidget {
  const _SalesSessionTile({
    required this.session,
    required this.amount,
    required this.dateText,
    required this.onOpenDetails,
  });

  final DailySessionSummaryModel session;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final VoidCallback onOpenDetails;

  DailyExpectedOpeningCount? _expectedFor(String currency) {
    return session.expectedOpeningCounts.firstWhereOrNull(
      (row) => row.currency == currency,
    );
  }

  String get _sessionSalesTotal {
    if (session.currencies.isEmpty) return amount(0);
    return session.currencies
        .map((row) => '${amount(row.salesCollected)} ${row.currency}')
        .join(' | ');
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'salesDailyStatusOpen'.tr;
      case 'closing_requested':
        return 'salesDailyStatusPending'.tr;
      case 'closed':
        return 'salesDailyStatusClosed'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.isDark.value
        ? AppColors.whiteColor
        : AppColors.secondaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: AppColors.primaryColor.withValues(alpha: .12),
          child: Icon(
            Icons.person_outline,
            color: AppColors.primaryColor,
            size: 20.sp,
          ),
        ),
        title: Text(
          session.employeeName ?? '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 3.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 3.h,
            children: [
              Text(session.businessDate, style: TextStyle(fontSize: 11.sp)),
              Text(_statusLabel(session.status),
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  )),
              Text(
                '${'instant_sales'.tr}: ${session.instantSalesCount}',
                style: TextStyle(fontSize: 11.sp),
              ),
              Text(
                '${'cashProfit'.tr}: ${session.profitSalesCount}',
                style: TextStyle(fontSize: 11.sp),
              ),
              Text(
                '${'salesDailySalesCollected'.tr}: $_sessionSalesTotal',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _DailyBoxMetric(
                  label: 'salesDailySalesCollected'.tr,
                  value: _sessionSalesTotal,
                ),
                _DailyBoxMetric(
                  label: 'salesDailyOpenedAt'.tr,
                  value: dateText(session.openedAt),
                ),
                _DailyBoxMetric(
                  label: 'salesDailyClosedAt'.tr,
                  value: dateText(session.closedAt),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          ...session.currencies.map((row) {
            final expected = _expectedFor(row.currency)?.expectedAmount ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.currency,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${'salesDailyExpectedOpeningShort'.tr}: ${amount(expected)}',
                    style:
                        TextStyle(color: AppColors.greyColor, fontSize: 11.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '${'salesDailyReceivedOpeningShort'.tr}: ${amount(row.openingFloat)}',
                    style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 8.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: onOpenDetails,
              icon: Icon(Icons.receipt_long_outlined, size: 18.sp),
              label: Text('details'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSessionDetailSheet extends StatelessWidget {
  const _SalesSessionDetailSheet({
    required this.detail,
    required this.amount,
    required this.dateText,
    required this.scrollController,
  });

  final DailySessionDetailModel detail;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final ScrollController scrollController;

  DailyExpectedOpeningCount? _expectedFor(String currency) {
    return detail.expectedOpeningCounts.firstWhereOrNull(
      (row) => row.currency == currency,
    );
  }

  String get _salesTotal {
    if (detail.currencies.isEmpty) return amount(0);
    return detail.currencies
        .map((row) => '${amount(row.salesCollected)} ${row.currency}')
        .join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final session = detail.session;
    final sales = [...detail.instantSales, ...detail.profitSales];

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          session.employeeName ?? '-',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4.h),
        Text(
          '${session.businessDate} | ${dateText(session.openedAt)} - ${dateText(session.closedAt)}',
          style: TextStyle(color: AppColors.greyColor, fontSize: 12.sp),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _DailyBoxMetric(
              label: 'instant_sales'.tr,
              value: detail.instantSalesCount.toString(),
            ),
            _DailyBoxMetric(
              label: 'cashProfit'.tr,
              value: detail.profitSalesCount.toString(),
            ),
            _DailyBoxMetric(
              label: 'salesDailyOrdersSection'.tr,
              value: detail.salesOrdersCount.toString(),
            ),
            _DailyBoxMetric(
              label: 'salesDailySalesCollected'.tr,
              value: _salesTotal,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          'salesDailyOpeningCountTitle'.tr,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8.h),
        ...detail.currencies.map(
          (row) {
            final expected = _expectedFor(row.currency)?.expectedAmount ?? 0;
            return Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.currency,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                        )),
                    SizedBox(height: 6.h),
                    _DetailLine(
                      label: 'salesDailyExpectedOpeningShort'.tr,
                      value: amount(expected),
                    ),
                    _DetailLine(
                      label: 'salesDailyReceivedOpening'.tr,
                      value: amount(row.openingFloat),
                    ),
                    _DetailLine(
                      label: 'salesDailySalesCollected'.tr,
                      value: amount(row.salesCollected),
                    ),
                    _DetailLine(
                      label: 'salesDailySystemBalance'.tr,
                      value: amount(row.systemBalance),
                    ),
                    _DetailLine(
                      label: 'salesDailyBoxBalance'.tr,
                      value: amount(row.boxBalance),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 14.h),
        Text(
          'salesDailySalesLog'.tr,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8.h),
        if (sales.isEmpty)
          Text('noData'.tr)
        else
          ...sales.map(
            (sale) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                sale.isCancelled
                    ? Icons.cancel_outlined
                    : Icons.receipt_long_outlined,
                color: sale.isCancelled
                    ? AppColors.redColor
                    : AppColors.primaryColor,
              ),
              title: Text(
                '${sale.displayInvoiceNumber} - ${sale.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  if (sale.createdByName != null)
                    '${'salesDailyMovementBy'.tr}: ${sale.createdByName}',
                  if (sale.buyerName != null) sale.buyerName!,
                  dateText(sale.createdAt),
                ].join('\n'),
              ),
              trailing: Text(
                amount(sale.paidAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: sale.isCancelled
                      ? AppColors.redColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
          ),
        if (detail.closingRequests.isNotEmpty) ...[
          SizedBox(height: 14.h),
          Text(
            'salesDailyClosingHistory'.tr,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          ...detail.closingRequests.map(
            (request) => Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      label: 'status'.tr,
                      value: request.status,
                    ),
                    _DetailLine(
                      label: 'salesDailyRequestedAt'.tr,
                      value: dateText(request.requestedAt),
                    ),
                    ...request.cashCounts.map(
                      (row) => _DetailLine(
                        label: row.currency,
                        value:
                            '${'salesDailyPhysicalCount'.tr}: ${amount(row.physicalCount)} | ${'salesDailyVariance'.tr}: ${amount(row.variance)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.greyColor, fontSize: 12.sp),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

enum _DailyBoxLogScope { today, yesterday, custom, all }

class _DailyBoxCard extends StatefulWidget {
  const _DailyBoxCard({
    required this.box,
    required this.logs,
    required this.amount,
    required this.date,
    required this.kindLabel,
    required this.kindColor,
    required this.onTransfer,
    required this.onOpenInvoice,
  });

  final ShownBoxesModel box;
  final List<BoxLogModel> logs;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final String kindLabel;
  final Color kindColor;
  final VoidCallback onTransfer;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  @override
  State<_DailyBoxCard> createState() => _DailyBoxCardState();
}

class _DailyBoxCardState extends State<_DailyBoxCard> {
  _DailyBoxLogScope _scope = _DailyBoxLogScope.today;
  DateTime? _customDate;

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dayKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(_dateOnly(date));

  double _signedValue(BoxLogModel log) {
    final isOut =
        log.fromBoxId == widget.box.boxId.toString() || log.type == 'minus';
    return isOut ? -log.value.abs() : log.value.abs();
  }

  List<BoxLogModel> _filteredLogs() {
    if (_scope == _DailyBoxLogScope.all) return widget.logs;

    final today = _dateOnly(DateTime.now());
    late final DateTime target;
    switch (_scope) {
      case _DailyBoxLogScope.today:
        target = today;
        break;
      case _DailyBoxLogScope.yesterday:
        target = today.subtract(const Duration(days: 1));
        break;
      case _DailyBoxLogScope.custom:
        target = _customDate == null ? today : _dateOnly(_customDate!);
        break;
      case _DailyBoxLogScope.all:
        target = today;
        break;
    }

    return widget.logs
        .where((log) => _dateOnly(log.createdAt) == target)
        .toList();
  }

  Map<String, List<BoxLogModel>> _groupByDay(List<BoxLogModel> logs) {
    final groups = <String, List<BoxLogModel>>{};
    for (final log in logs) {
      groups
          .putIfAbsent(_dayKey(log.createdAt), () => <BoxLogModel>[])
          .add(log);
    }
    for (final group in groups.values) {
      group.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return groups;
  }

  String _dayTitle(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    final today = _dateOnly(DateTime.now());
    final current = _dateOnly(date);
    if (current == today) return 'today'.tr;
    if (current == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr;
    }
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat('EEEE d/M/yyyy', locale).format(current);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _customDate = picked;
      _scope = _DailyBoxLogScope.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.isDark.value
        ? AppColors.whiteColor
        : AppColors.secondaryColor;
    final mutedColor = ThemeService.isDark.value
        ? AppColors.graywhiteColor
        : AppColors.greyColor;
    final cardColor = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : AppColors.whiteColor;
    final filteredLogs = _filteredLogs();
    final groupedLogs = _groupByDay(filteredLogs);

    return Card(
      elevation: 0,
      color: cardColor,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.operationalCardBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(14.w),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: widget.kindColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: widget.kindColor,
              size: 22.sp,
            ),
          ),
          title: Text(
            widget.box.boxName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 5.h),
            child: Wrap(
              spacing: 10.w,
              runSpacing: 3.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.kindLabel,
                  style: TextStyle(
                    color: widget.kindColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.amount(widget.box.totalBalance)} ${widget.box.currency}',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          children: [
            SizedBox(
              height: 40.h,
              child: ElevatedButton.icon(
                onPressed: widget.onTransfer,
                icon: Icon(Icons.swap_horiz, size: 20.sp),
                label: Text('transferToAnotherBox'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  foregroundColor: AppColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'dailyBoxDayLog'.tr,
              style: TextStyle(
                color: textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            _DailyBoxLogFilterBar(
              scope: _scope,
              customDate: _customDate,
              onChanged: (scope) => setState(() => _scope = scope),
              onPickDate: () => _pickDate(context),
            ),
            SizedBox(height: 10.h),
            if (filteredLogs.isEmpty)
              Text(
                'noData'.tr,
                style: TextStyle(color: mutedColor, fontSize: 12.sp),
              )
            else
              ...groupedLogs.entries.map(
                (entry) => _DailyBoxDayGroup(
                  title: _dayTitle(entry.key),
                  logs: entry.value,
                  amount: widget.amount,
                  date: widget.date,
                  boxId: widget.box.boxId.toString(),
                  signedValue: _signedValue,
                  onOpenInvoice: widget.onOpenInvoice,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyBoxLogFilterBar extends StatelessWidget {
  const _DailyBoxLogFilterBar({
    required this.scope,
    required this.customDate,
    required this.onChanged,
    required this.onPickDate,
  });

  final _DailyBoxLogScope scope;
  final DateTime? customDate;
  final ValueChanged<_DailyBoxLogScope> onChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8.w),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.secondaryColor,
          backgroundColor: AppColors.whiteColor,
          side: BorderSide(
            color: selected
                ? AppColors.secondaryColor
                : AppColors.operationalCardBorder,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          labelStyle: TextStyle(
            color: selected ? AppColors.whiteColor : AppColors.secondaryColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    final customLabel = customDate == null
        ? 'chooseDate'.tr
        : DateFormat('d/M/yyyy', locale).format(customDate!);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: 'today'.tr,
            selected: scope == _DailyBoxLogScope.today,
            onTap: () => onChanged(_DailyBoxLogScope.today),
          ),
          chip(
            label: 'yesterday'.tr,
            selected: scope == _DailyBoxLogScope.yesterday,
            onTap: () => onChanged(_DailyBoxLogScope.yesterday),
          ),
          chip(
            label: customLabel,
            selected: scope == _DailyBoxLogScope.custom,
            onTap: onPickDate,
          ),
          chip(
            label: 'dailyBoxAllDays'.tr,
            selected: scope == _DailyBoxLogScope.all,
            onTap: () => onChanged(_DailyBoxLogScope.all),
          ),
        ],
      ),
    );
  }
}

class _DailyBoxDayGroup extends StatelessWidget {
  const _DailyBoxDayGroup({
    required this.title,
    required this.logs,
    required this.amount,
    required this.date,
    required this.boxId,
    required this.signedValue,
    required this.onOpenInvoice,
  });

  final String title;
  final List<BoxLogModel> logs;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final String boxId;
  final double Function(BoxLogModel log) signedValue;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final sortedAsc = [...logs]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final total = logs.fold<double>(0, (sum, log) => sum + signedValue(log));
    final invoiceCount = logs.where((log) {
      final invoice = log.invoiceNumber?.trim();
      return invoice != null && invoice.isNotEmpty;
    }).length;
    double? opening;
    for (final log in sortedAsc) {
      if (log.boxBalanceBefore != null) {
        opening = log.boxBalanceBefore;
        break;
      }
    }
    double? closing;
    for (final log in sortedAsc.reversed) {
      if (log.boxBalanceAfter != null) {
        closing = log.boxBalanceAfter;
        break;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 6.h,
            children: [
              _DailyBoxMetric(
                label: 'dailyBoxDayTotal'.tr,
                value: amount(total),
              ),
              _DailyBoxMetric(
                label: 'dailyBoxInvoicesCount'.tr,
                value: invoiceCount.toString(),
              ),
              if (opening != null)
                _DailyBoxMetric(
                  label: 'openingBalance'.tr,
                  value: amount(opening),
                ),
              if (closing != null)
                _DailyBoxMetric(
                  label: 'closingBalance'.tr,
                  value: amount(closing),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          ...logs.map((log) => _DailyBoxLogTile(
                log: log,
                boxId: boxId,
                amount: amount,
                date: date,
                onOpenInvoice: onOpenInvoice,
              )),
        ],
      ),
    );
  }
}

class _DailyBoxMetric extends StatelessWidget {
  const _DailyBoxMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DailyBoxLogTile extends StatelessWidget {
  const _DailyBoxLogTile({
    required this.log,
    required this.boxId,
    required this.amount,
    required this.date,
    required this.onOpenInvoice,
  });

  final BoxLogModel log;
  final String boxId;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  bool get _isOut => log.fromBoxId == boxId || log.type == 'minus';
  bool get _hasMaintenanceInvoice =>
      log.maintenanceId != null && log.maintenanceId!.trim().isNotEmpty;

  String? get _noteText {
    final note = log.note?.trim();
    if (note == null || note.isEmpty || note == log.description.trim()) {
      return null;
    }
    return note;
  }

  @override
  Widget build(BuildContext context) {
    final color = _isOut ? AppColors.redColor : AppColors.customGreen1;
    final value = log.value.abs();
    final invoiceNumber = log.invoiceNumber?.trim();
    final note = _noteText;

    return InkWell(
      onTap: _hasMaintenanceInvoice ? () => onOpenInvoice(log) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          children: [
            Icon(
              _isOut
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    date(log.createdAt),
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 11.sp,
                    ),
                  ),
                  if (note != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (invoiceNumber != null && invoiceNumber.isNotEmpty)
                    Text(
                      '${'billNumber'.tr}: $invoiceNumber',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${_isOut ? '-' : '+'}${amount(value)}',
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
