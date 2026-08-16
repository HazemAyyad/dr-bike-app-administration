import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../../../maintenance/data/datasources/maintenance_datasource.dart';
import '../../../maintenance/domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
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
  List<DailySessionSummaryModel> _maintenanceSessions = const [];
  bool _loadingSalesSessions = false;
  bool _loadingMaintenanceSessions = false;
  _DailyBoxLogScope _salesSessionScope = _DailyBoxLogScope.today;
  _DailyBoxLogScope _maintenanceSessionScope = _DailyBoxLogScope.today;
  DateTime? _salesSessionCustomDate;
  DateTime? _maintenanceSessionCustomDate;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['filter'] != null) {
      final filter = args['filter'].toString();
      if (['all', 'sales', 'orders', 'maintenance'].contains(filter)) {
        _filter = filter;
      }
    }
    _loadSalesSessions();
    _loadMaintenanceSessions();
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

  Future<void> _loadMaintenanceSessions() async {
    setState(() => _loadingMaintenanceSessions = true);
    try {
      AppDependencyRegistry.ensureMaintenance();
      final ds = Get.find<MaintenanceDatasource>();
      final today = _dateOnly(DateTime.now());
      String? fromDate;
      String? toDate;
      switch (_maintenanceSessionScope) {
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
          final target = _maintenanceSessionCustomDate == null
              ? today
              : _dateOnly(_maintenanceSessionCustomDate!);
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
      setState(() => _maintenanceSessions = sessions);
    } catch (_) {
      if (!mounted) return;
      setState(() => _maintenanceSessions = const []);
    } finally {
      if (mounted) setState(() => _loadingMaintenanceSessions = false);
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

  Future<void> _pickMaintenanceSessionDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceSessionCustomDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _maintenanceSessionCustomDate = picked;
      _maintenanceSessionScope = _DailyBoxLogScope.custom;
    });
    await _loadMaintenanceSessions();
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

  Future<void> _showMaintenanceSessionDetails(
    BuildContext context,
    DailySessionSummaryModel session,
  ) async {
    AppDependencyRegistry.ensureMaintenance();
    final ds = Get.find<MaintenanceDatasource>();

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
                  mode: _DailySessionViewMode.maintenance,
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
        final showMaintenanceSessions =
            _filter == 'all' || _filter == 'maintenance';
        final hasSalesSessions = showSalesSessions && _salesSessions.isNotEmpty;
        final hasMaintenanceSessions =
            showMaintenanceSessions && _maintenanceSessions.isNotEmpty;
        if ((controller.isLoading.value ||
                _loadingSalesSessions ||
                _loadingMaintenanceSessions) &&
            boxes.isEmpty &&
            !hasSalesSessions &&
            !hasMaintenanceSessions) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.pullToRefresh(),
              _loadSalesSessions(),
              _loadMaintenanceSessions(),
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
              if (showSalesSessions &&
                  (boxes.isNotEmpty || showMaintenanceSessions))
                SizedBox(height: 12.h),
              if (showMaintenanceSessions)
                _SalesSessionsSection(
                  sessions: _maintenanceSessions,
                  loading: _loadingMaintenanceSessions,
                  scope: _maintenanceSessionScope,
                  customDate: _maintenanceSessionCustomDate,
                  amount: _amount,
                  dateText: _dateText,
                  mode: _DailySessionViewMode.maintenance,
                  onScopeChanged: (scope) async {
                    setState(() => _maintenanceSessionScope = scope);
                    await _loadMaintenanceSessions();
                  },
                  onPickDate: () => _pickMaintenanceSessionDate(context),
                  onOpenDetails: (session) =>
                      _showMaintenanceSessionDetails(context, session),
                ),
              if (showMaintenanceSessions &&
                  boxes.isNotEmpty &&
                  _maintenanceSessions.isEmpty)
                SizedBox(height: 12.h),
              if (_filter == 'maintenance' && _maintenanceSessions.isEmpty)
                _MaintenanceBoxesSection(
                  boxes: boxes,
                  logsForBox: _boxLogs,
                  amount: _amount,
                  date: _date,
                  onTransfer: (box) {
                    controller.transferToBoxIdController.clear();
                    controller.transferTotalController.clear();
                    Get.dialog(
                      TransferBalanceWidget(
                        boxId: box.boxId,
                        currency: box.currency,
                      ),
                    );
                  },
                  onOpenInvoice: (log) => _openMaintenanceInvoice(context, log),
                )
              else if (boxes.isEmpty &&
                  !hasSalesSessions &&
                  !hasMaintenanceSessions)
                SizedBox(height: 360.h, child: const ShowNoData())
              else
                ...boxes.where((box) {
                  if (_filter == 'all' && _boxKind(box) == 'maintenance') {
                    return _maintenanceSessions.isEmpty;
                  }
                  return true;
                }).map((box) => _DailyBoxCard(
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

enum _DailySessionViewMode { sales, maintenance }

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
    this.mode = _DailySessionViewMode.sales,
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
  final _DailySessionViewMode mode;

  bool get _isMaintenance => mode == _DailySessionViewMode.maintenance;

  String get _sectionTitle =>
      _isMaintenance ? 'dailyBoxMaintenance'.tr : 'salesDailyHistoryTitle'.tr;

  String get _totalLabel =>
      _isMaintenance ? 'المتحصل كاش' : 'salesDailySalesCollected'.tr;

  IconData get _sectionIcon => _isMaintenance
      ? Icons.build_circle_outlined
      : Icons.point_of_sale_outlined;

  Color get _sectionColor =>
      _isMaintenance ? const Color(0xFF007C89) : AppColors.primaryColor;

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
            _sectionIcon,
            color: _sectionColor,
            size: 22.sp,
          ),
          title: Text(
            _sectionTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '$_totalLabel: $allTotal',
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
                  mode: mode,
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
    this.mode = _DailySessionViewMode.sales,
  });

  final String title;
  final List<DailySessionSummaryModel> sessions;
  final String totalText;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final ValueChanged<DailySessionSummaryModel> onOpenDetails;
  final _DailySessionViewMode mode;

  bool get _isMaintenance => mode == _DailySessionViewMode.maintenance;

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
          '${_isMaintenance ? 'المتحصل كاش' : 'salesDailySalesCollected'.tr}: $totalText',
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
                mode: mode,
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
    this.mode = _DailySessionViewMode.sales,
  });

  final DailySessionSummaryModel session;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final VoidCallback onOpenDetails;
  final _DailySessionViewMode mode;

  bool get _isMaintenance => mode == _DailySessionViewMode.maintenance;

  Color get _accentColor =>
      _isMaintenance ? const Color(0xFF007C89) : AppColors.primaryColor;

  String get _collectedLabel =>
      _isMaintenance ? 'المتحصل كاش' : 'salesDailySalesCollected'.tr;

  String get _primaryCountLabel =>
      _isMaintenance ? 'عمليات الصيانة' : 'instant_sales'.tr;

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
          backgroundColor: _accentColor.withValues(alpha: .12),
          child: Icon(
            _isMaintenance ? Icons.build_circle_outlined : Icons.person_outline,
            color: _accentColor,
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
                    color: _accentColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  )),
              Text(
                '$_primaryCountLabel: ${session.instantSalesCount}',
                style: TextStyle(fontSize: 11.sp),
              ),
              if (!_isMaintenance)
                Text(
                  '${'cashProfit'.tr}: ${session.profitSalesCount}',
                  style: TextStyle(fontSize: 11.sp),
                ),
              Text(
                '$_collectedLabel: $_sessionSalesTotal',
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
                  label: _collectedLabel,
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
    this.mode = _DailySessionViewMode.sales,
  });

  final DailySessionDetailModel detail;
  final String Function(double value) amount;
  final String Function(String? value) dateText;
  final ScrollController scrollController;
  final _DailySessionViewMode mode;

  bool get _isMaintenance => mode == _DailySessionViewMode.maintenance;

  String get _collectedLabel =>
      _isMaintenance ? 'المتحصل كاش' : 'salesDailySalesCollected'.tr;

  String get _primaryCountLabel =>
      _isMaintenance ? 'عمليات الصيانة' : 'instant_sales'.tr;

  String get _logTitle =>
      _isMaintenance ? 'سجل دفعات الصيانة' : 'salesDailySalesLog'.tr;

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
              label: _primaryCountLabel,
              value: detail.instantSalesCount.toString(),
            ),
            if (!_isMaintenance)
              _DailyBoxMetric(
                label: 'cashProfit'.tr,
                value: detail.profitSalesCount.toString(),
              ),
            if (!_isMaintenance)
              _DailyBoxMetric(
                label: 'salesDailyOrdersSection'.tr,
                value: detail.salesOrdersCount.toString(),
              ),
            _DailyBoxMetric(
              label: _collectedLabel,
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
                      label: _collectedLabel,
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
          _logTitle,
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

class _MaintenanceBoxesSection extends StatefulWidget {
  const _MaintenanceBoxesSection({
    required this.boxes,
    required this.logsForBox,
    required this.amount,
    required this.date,
    required this.onTransfer,
    required this.onOpenInvoice,
  });

  final List<ShownBoxesModel> boxes;
  final List<BoxLogModel> Function(ShownBoxesModel box) logsForBox;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final ValueChanged<ShownBoxesModel> onTransfer;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  @override
  State<_MaintenanceBoxesSection> createState() =>
      _MaintenanceBoxesSectionState();
}

class _MaintenanceBoxesSectionState extends State<_MaintenanceBoxesSection> {
  _DailyBoxLogScope _scope = _DailyBoxLogScope.today;
  DateTime? _customDate;

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _dayTitle(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    final today = _dateOnly(DateTime.now());
    final day = _dateOnly(date);
    if (day == today) return 'today'.tr;
    if (day == today.subtract(const Duration(days: 1))) return 'yesterday'.tr;
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat('EEEE d/M/yyyy', locale).format(day);
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

  bool _matchesScope(BoxLogModel log) {
    final today = _dateOnly(DateTime.now());
    final logDay = _dateOnly(log.createdAt);
    switch (_scope) {
      case _DailyBoxLogScope.today:
        return logDay == today;
      case _DailyBoxLogScope.yesterday:
        return logDay == today.subtract(const Duration(days: 1));
      case _DailyBoxLogScope.custom:
        final target = _customDate == null ? today : _dateOnly(_customDate!);
        return logDay == target;
      case _DailyBoxLogScope.all:
        return true;
    }
  }

  List<BoxLogModel> _filteredLogsForBox(ShownBoxesModel box) {
    final logs = widget.logsForBox(box).where(_matchesScope).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  double _paidValue(BoxLogModel log) {
    if (log.type == 'minus') return 0;
    return log.value.abs();
  }

  String _totalsText(List<BoxLogModel> logs) {
    final cash = logs
        .where((log) => log.type != 'minus')
        .fold<double>(0, (sum, log) => sum + _paidValue(log));
    final parts = <String>[
      'كاش: ${widget.amount(cash)}',
    ];
    return parts.join(' | ');
  }

  String _ownerName(ShownBoxesModel box) {
    final parts = box.boxName.split(' - ');
    if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
      return parts[1].trim();
    }
    return box.boxName;
  }

  bool _isCurrentShownBox(ShownBoxesModel box) {
    final currentBoxId = _currentMaintenanceBoxId();
    if (currentBoxId != null) {
      return box.boxId == currentBoxId;
    }
    return BoxesServes().shownBoxes.any((item) => item.boxId == box.boxId);
  }

  int? _currentMaintenanceBoxId() {
    if (!Get.isRegistered<MaintenanceController>()) return null;
    final payload = Get.find<MaintenanceController>().dailyBoxPayload;
    final box = payload['box'];
    if (box is Map) {
      final id = box['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return null;
  }

  bool get _shouldShowCurrentEmptyBoxes {
    if (_scope == _DailyBoxLogScope.today) return true;
    if (_scope != _DailyBoxLogScope.custom || _customDate == null) {
      return false;
    }
    return _dateOnly(_customDate!) == _dateOnly(DateTime.now());
  }

  Map<String, List<_MaintenanceBoxLogs>> _groupByDay() {
    final grouped = <String, List<_MaintenanceBoxLogs>>{};
    final todayKey = _dayKey(DateTime.now());
    for (final box in widget.boxes) {
      final logs = _filteredLogsForBox(box);
      if (logs.isEmpty) {
        if (_shouldShowCurrentEmptyBoxes && _isCurrentShownBox(box)) {
          grouped
              .putIfAbsent(todayKey, () => [])
              .add(_MaintenanceBoxLogs(box: box, logs: const []));
        }
        continue;
      }
      final logsByDay = <String, List<BoxLogModel>>{};
      for (final log in logs) {
        logsByDay.putIfAbsent(_dayKey(log.createdAt), () => []).add(log);
      }
      for (final entry in logsByDay.entries) {
        grouped
            .putIfAbsent(entry.key, () => [])
            .add(_MaintenanceBoxLogs(box: box, logs: entry.value));
      }
    }
    for (final groups in grouped.values) {
      groups.sort((a, b) => _ownerName(a.box).compareTo(_ownerName(b.box)));
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = widget.boxes.expand(_filteredLogsForBox).toList();
    final grouped = _groupByDay();
    final mutedColor = AppColors.greyColor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xFF007C89).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: const Color(0xFF007C89),
              size: 24.sp,
            ),
          ),
          title: Text(
            'صناديق الصيانة اليومية',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            'الصيانة اليومية ${_totalsText(allLogs)} شيكل',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            _DailyBoxLogFilterBar(
              scope: _scope,
              customDate: _customDate,
              onChanged: (scope) => setState(() => _scope = scope),
              onPickDate: () => _pickDate(context),
            ),
            SizedBox(height: 10.h),
            if (widget.boxes.isEmpty || grouped.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'noData'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 12.sp),
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => _MaintenanceDayGroup(
                  title: _dayTitle(entry.key),
                  groups: entry.value,
                  totalsText: _totalsText(
                    entry.value.expand((group) => group.logs).toList(),
                  ),
                  amount: widget.amount,
                  date: widget.date,
                  ownerName: _ownerName,
                  onTransfer: widget.onTransfer,
                  onOpenInvoice: widget.onOpenInvoice,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceBoxLogs {
  const _MaintenanceBoxLogs({
    required this.box,
    required this.logs,
  });

  final ShownBoxesModel box;
  final List<BoxLogModel> logs;
}

class _MaintenanceDayGroup extends StatelessWidget {
  const _MaintenanceDayGroup({
    required this.title,
    required this.groups,
    required this.totalsText,
    required this.amount,
    required this.date,
    required this.ownerName,
    required this.onTransfer,
    required this.onOpenInvoice,
  });

  final String title;
  final List<_MaintenanceBoxLogs> groups;
  final String totalsText;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final String Function(ShownBoxesModel box) ownerName;
  final ValueChanged<ShownBoxesModel> onTransfer;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          title: Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '$totalsText شيكل',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: groups
              .map(
                (group) => _MaintenanceBoxSessionTile(
                  box: group.box,
                  logs: group.logs,
                  ownerName: ownerName(group.box),
                  amount: amount,
                  date: date,
                  onTransfer: () => onTransfer(group.box),
                  onOpenInvoice: onOpenInvoice,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MaintenanceBoxSessionTile extends StatelessWidget {
  const _MaintenanceBoxSessionTile({
    required this.box,
    required this.logs,
    required this.ownerName,
    required this.amount,
    required this.date,
    required this.onTransfer,
    required this.onOpenInvoice,
  });

  final ShownBoxesModel box;
  final List<BoxLogModel> logs;
  final String ownerName;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final VoidCallback onTransfer;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  String _totalsText() {
    double cash = 0;
    for (final log in logs) {
      if (log.type == 'minus') continue;
      final value = log.value.abs();
      cash += value;
    }
    return [
      'كاش: ${amount(cash)}',
    ].join(' | ');
  }

  List<_MaintenanceRequestGroup> _requestGroups() {
    final grouped = <String, List<BoxLogModel>>{};
    for (final log in logs) {
      final maintenanceId = log.maintenanceId?.trim();
      final invoice = log.invoiceNumber?.trim();
      final key = maintenanceId != null && maintenanceId.isNotEmpty
          ? 'maintenance:$maintenanceId'
          : invoice != null && invoice.isNotEmpty
              ? 'invoice:$invoice'
              : 'log:${log.id}';
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final groups =
        grouped.values.map((items) => _MaintenanceRequestGroup(items)).toList();
    groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final requestGroups = _requestGroups();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          leading: CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF007C89).withValues(alpha: .12),
            child: Icon(
              Icons.person_outline,
              color: const Color(0xFF007C89),
              size: 22.sp,
            ),
          ),
          title: Text(
            ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            [
              'الرصيد: ${amount(box.totalBalance)} ${box.currency}',
              _totalsText(),
            ].join(' | '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.center,
              child: ElevatedButton.icon(
                onPressed: onTransfer,
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  'transferBalanceToAnotherBox'.tr ==
                          'transferBalanceToAnotherBox'
                      ? 'ترحيل لصندوق آخر'
                      : 'transferBalanceToAnotherBox'.tr,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  foregroundColor: AppColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'حركات صندوق $ownerName',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 8.h),
            if (requestGroups.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'noData'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...requestGroups.map(
                (group) => _MaintenanceRequestLogTile(
                  group: group,
                  amount: amount,
                  date: date,
                  onOpenInvoice: onOpenInvoice,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceRequestGroup {
  _MaintenanceRequestGroup(List<BoxLogModel> logs)
      : logs = [...logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final List<BoxLogModel> logs;

  BoxLogModel get primary => logs.first;
  DateTime get createdAt => primary.createdAt;

  String? get maintenanceId {
    for (final log in logs) {
      final value = log.maintenanceId?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? get invoiceNumber {
    for (final log in logs) {
      final value = log.invoiceNumber?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? get note {
    for (final log in logs) {
      final value = log.note?.trim();
      if (value != null &&
          value.isNotEmpty &&
          value != log.description.trim()) {
        return value;
      }
    }
    return null;
  }

  double get cash => _sumWhere((log) =>
      log.affectsCashBalance &&
      (log.paymentMethod == null || log.paymentMethod == 'cash'));

  double get paidTotal => cash;

  double _sumWhere(bool Function(BoxLogModel log) test) {
    return logs
        .where((log) => log.type != 'minus' && test(log))
        .fold<double>(0, (sum, log) => sum + log.value.abs());
  }
}

class _MaintenanceRequestLogTile extends StatelessWidget {
  const _MaintenanceRequestLogTile({
    required this.group,
    required this.amount,
    required this.date,
    required this.onOpenInvoice,
  });

  final _MaintenanceRequestGroup group;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  bool get _canOpenInvoice {
    final maintenanceId = group.maintenanceId;
    return maintenanceId != null && maintenanceId.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceId = group.maintenanceId;
    final invoiceNumber = group.invoiceNumber;
    final note = group.note;

    return InkWell(
      onTap: _canOpenInvoice ? () => onOpenInvoice(group.primary) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.operationalCardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.arrow_downward_rounded,
              color: AppColors.customGreen1,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maintenanceId == null
                        ? 'حركة صيانة'
                        : 'طلب صيانة #$maintenanceId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    date(group.createdAt),
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (invoiceNumber != null)
                    Text(
                      '${'billNumber'.tr}: $invoiceNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (note != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      if (group.cash > 0)
                        _MaintenancePaymentPill(
                          label: 'كاش',
                          value: amount(group.cash),
                          color: AppColors.customGreen1,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (group.paidTotal > 0)
                  Text(
                    '+${amount(group.paidTotal)}',
                    style: TextStyle(
                      color: AppColors.customGreen1,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenancePaymentPill extends StatelessWidget {
  const _MaintenancePaymentPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
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

  bool get _isMaintenanceBox =>
      widget.box.type.toLowerCase() == 'daily_maintenance' ||
      widget.box.boxName.contains('الصيانة');

  String? get _boxOwnerName {
    final parts = widget.box.boxName.split(' - ');
    if (parts.length >= 2) {
      final owner = parts[1].trim();
      return owner.isEmpty ? null : owner;
    }
    return null;
  }

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
          initiallyExpanded: _isMaintenanceBox,
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
            _isMaintenanceBox ? 'صندوق الصيانة اليومي' : widget.box.boxName,
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
                if (_boxOwnerName != null)
                  Text(
                    'الصندوق باسم: $_boxOwnerName',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
              _isMaintenanceBox
                  ? 'حركات صندوق ${_boxOwnerName ?? 'الصيانة'}'
                  : 'dailyBoxDayLog'.tr,
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
                  cashOnly: _isMaintenanceBox,
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
    required this.cashOnly,
    required this.onOpenInvoice,
  });

  final String title;
  final List<BoxLogModel> logs;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final String boxId;
  final double Function(BoxLogModel log) signedValue;
  final bool cashOnly;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final sortedAsc = [...logs]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final total = logs.fold<double>(0, (sum, log) => sum + signedValue(log));
    final cashTotal = cashOnly
        ? logs
            .where((log) => log.type != 'minus')
            .fold<double>(0, (sum, log) => sum + log.value.abs())
        : logs
            .where((log) =>
                log.affectsCashBalance &&
                (log.paymentMethod == null || log.paymentMethod == 'cash'))
            .fold<double>(0, (sum, log) => sum + log.value.abs());
    final visaTotal = logs
        .where((log) => log.paymentMethod == 'visa')
        .fold<double>(0, (sum, log) => sum + log.value.abs());
    final transferTotal = logs
        .where((log) => log.paymentMethod == 'bank_transfer')
        .fold<double>(0, (sum, log) => sum + log.value.abs());
    final debtTotal = logs
        .where((log) => log.paymentMethod == 'debt')
        .fold<double>(0, (sum, log) => sum + log.value.abs());
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
              if (cashTotal > 0)
                _DailyBoxMetric(
                  label: 'كاش',
                  value: amount(cashTotal),
                ),
              if (!cashOnly && visaTotal > 0)
                _DailyBoxMetric(
                  label: 'فيزا',
                  value: amount(visaTotal),
                ),
              if (!cashOnly && transferTotal > 0)
                _DailyBoxMetric(
                  label: 'حوالة',
                  value: amount(transferTotal),
                ),
              if (!cashOnly && debtTotal > 0)
                _DailyBoxMetric(
                  label: 'دين',
                  value: amount(debtTotal),
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
                cashOnly: cashOnly,
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
    required this.cashOnly,
    required this.onOpenInvoice,
  });

  final BoxLogModel log;
  final String boxId;
  final String Function(double value) amount;
  final String Function(DateTime date) date;
  final bool cashOnly;
  final ValueChanged<BoxLogModel> onOpenInvoice;

  bool get _isOut => log.fromBoxId == boxId || log.type == 'minus';
  bool get _hasMaintenanceInvoice =>
      log.maintenanceId != null && log.maintenanceId!.trim().isNotEmpty;
  String? get _paymentMethodLabel {
    if (cashOnly && log.type != 'minus') return 'كاش';
    switch (log.paymentMethod) {
      case 'cash':
        return 'كاش';
      case 'visa':
        return 'فيزا';
      case 'bank_transfer':
        return 'حوالة';
      case 'debt':
        return 'دين';
    }
    return null;
  }

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
    final paymentMethodLabel = _paymentMethodLabel;

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
                  if (paymentMethodLabel != null)
                    Text(
                      paymentMethodLabel,
                      style: TextStyle(
                        color: log.affectsCashBalance
                            ? AppColors.customGreen1
                            : AppColors.primaryColor,
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
