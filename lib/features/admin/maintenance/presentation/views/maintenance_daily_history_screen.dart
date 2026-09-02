import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../../sales/data/models/daily_session_model.dart';
import '../../../sales/presentation/widgets/sales_daily_ui_widgets.dart';
import '../../data/repositories/maintenance_implement.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDailyHistoryScreen extends StatefulWidget {
  const MaintenanceDailyHistoryScreen({
    Key? key,
    this.embedded = false,
    this.drawerSelector,
  }) : super(key: key);

  final bool embedded;
  final Widget? drawerSelector;

  @override
  State<MaintenanceDailyHistoryScreen> createState() =>
      _MaintenanceDailyHistoryScreenState();
}

class _MaintenanceDailyHistoryScreenState
    extends State<MaintenanceDailyHistoryScreen> {
  MaintenanceController get controller => Get.find<MaintenanceController>();
  final List<DailySessionSummaryModel> _today = [];
  final List<DailySessionSummaryModel> _history = [];
  bool _loading = true;
  bool _showHistory = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
      final args = Get.arguments;
      final shouldOpen = args is Map && args['openDrawer'] == true;
      if (mounted && shouldOpen && controller.canRequestMaintenanceDailyOpen) {
        await _openDrawer(context);
      }
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    _loadError = null;
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final results = await Future.wait<dynamic>([
        _refreshCurrentSessionSafely(),
        datasource
            .getDailySessionsHistory()
            .timeout(const Duration(seconds: 20)),
      ]);
      final history = results[1] as List<DailySessionSummaryModel>;
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (!mounted) return;
      _today
        ..clear()
        ..addAll(history.where((item) => item.businessDate == today));
      _history
        ..clear()
        ..addAll(history);
      if (userType == 'admin') {
        await controller.loadMaintenanceDailyClosingRequests();
      }
    } on TimeoutException {
      _loadError = 'استغرق تحميل الصناديق وقتاً طويلاً';
    } catch (_) {
      _loadError = 'تعذر تحميل صناديق الصيانة';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshCurrentSessionSafely() async {
    try {
      await controller.loadMaintenanceDailySession().timeout(
            const Duration(seconds: 20),
          );
    } catch (_) {
      // The history list can still render if refreshing the status request fails.
    }
  }

  DailySessionSummaryModel? get _active => _history.firstWhereOrNull(
        (item) => item.isOpen || item.isClosingRequested,
      );

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    SizedBox(height: 10.h),
                    Text(_loadError!),
                    SizedBox(height: 10.h),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 18.h),
                  children: [
                    _activeCard(context),
                    SizedBox(height: 7.h),
                    if (widget.drawerSelector != null) ...[
                      widget.drawerSelector!,
                      SizedBox(height: 7.h),
                    ],
                    _summaryStrip(),
                    if (userType == 'admin' &&
                        controller.dailyClosingRequests.isNotEmpty) ...[
                      SizedBox(height: 7.h),
                      _inlineClosingRequests(),
                    ],
                    SizedBox(height: 7.h),
                    _modeSelector(),
                    SizedBox(height: 7.h),
                    if ((_showHistory ? _history : _today).isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: const ShowNoData(),
                      )
                    else
                      ...(_showHistory ? _history : _today).map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: _sessionTile(context, item),
                        ),
                      ),
                  ],
                ),
              );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'صناديق الصيانة اليومية',
        action: false,
      ),
      body: body,
    );
  }

  Widget _activeCard(BuildContext context) {
    final active = _active;
    final closing = active?.isClosingRequested == true ||
        controller.isMaintenanceDailyBoxClosingRequested;
    final open = active?.isOpen == true || controller.isMaintenanceDailyBoxOpen;
    final color = closing
        ? Colors.orange
        : open
            ? Colors.green
            : Colors.redAccent;
    final status = closing
        ? 'بانتظار الإغلاق'
        : open
            ? 'مفتوح الآن'
            : 'لا يوجد صندوق مفتوح';
    final balance = active?.currencies
            .firstWhereOrNull((row) => row.currency == 'شيكل')
            ?.systemBalance ??
        controller.maintenanceDailyExpectedClosingBalance;
    final employeeName = active?.employeeName ??
        controller.maintenanceDailyEmployeeName ??
        controller.maintenanceDailyBlockedByEmployeeName;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صندوق الصيانة اليومي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${balance.toStringAsFixed(2)} ₪',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'الرصيد الحالي',
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
          ),
          SizedBox(height: 7.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    'فتحه: ${employeeName ?? '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                  ),
                ),
                const Icon(Icons.schedule_outlined, color: Colors.white70),
                SizedBox(width: 4.w),
                Text(
                  _time(active?.openedAt),
                  style: TextStyle(color: Colors.white, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          if (controller.canRequestMaintenanceDailyClosing) ...[
            SizedBox(height: 7.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  await Get.toNamed(AppRoutes.MAINTENANCEDAILYCLOSESCREEN);
                  await _load();
                },
                icon: const Icon(Icons.lock_clock_outlined),
                label: const Text('تقديم طلب إغلاق الصندوق'),
              ),
            ),
          ] else if (closing) ...[
            SizedBox(height: 7.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white54),
              ),
              child: const Text(
                'طلب الإغلاق قيد مراجعة الإدارة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else if (controller.canRequestMaintenanceDailyOpen) ...[
            SizedBox(height: 7.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _openDrawer(context),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('فتح صندوق الصيانة اليومي'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _time(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour >= 12 ? 'م' : 'ص'}';
  }

  Widget _summaryStrip() {
    final all = _history;
    return SalesDailySummaryStrip(
      openCount: all.where((e) => e.isOpen).length,
      pendingCount: all.where((e) => e.isClosingRequested).length,
      closedCount: all.where((e) => e.status == 'closed').length,
    );
  }

  Widget _inlineClosingRequests() {
    final requests = controller.dailyClosingRequests;
    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_outlined, color: Colors.orange),
              SizedBox(width: 7.w),
              Text(
                'طلبات إغلاق صندوق الصيانة (${requests.length})',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          ...requests.map((request) {
            final requestId = int.tryParse('${request['id'] ?? ''}');
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request['employee_name'] ?? '—'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'تاريخ الصندوق: ${request['business_date'] ?? '—'}\n'
                    'طلبات الصيانة: ${request['maintenances_count'] ?? 0}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      TextButton.icon(
                        onPressed: requestId == null
                            ? null
                            : () async {
                                await controller.rejectMaintenanceDailyClosing(
                                  requestId,
                                );
                                await _load();
                              },
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.red),
                        label: const Text(
                          'رفض',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: requestId == null
                            ? null
                            : () async {
                                await Get.toNamed(
                                  AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
                                  arguments: {
                                    'mode': 'review',
                                    'request': request,
                                  },
                                );
                                await _load();
                              },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('موافقة'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Get.toNamed(
                            AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
                            arguments: {
                              'mode': 'review',
                              'request': request,
                            },
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('التفاصيل والترحيل'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _modeSelector() {
    return SegmentedButton<bool>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        ),
      ),
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.today_outlined),
          label: Text('صناديق اليوم'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.history_rounded),
          label: Text('السجل السابق'),
        ),
      ],
      selected: {_showHistory},
      onSelectionChanged: (value) => setState(() => _showHistory = value.first),
      showSelectedIcon: false,
    );
  }

  Widget _sessionTile(BuildContext context, DailySessionSummaryModel item) {
    return SalesDailySessionTile(
      item: item,
      onTap: () => Get.toNamed(
        AppRoutes.SALESDAILYSESSIONDETAILSCREEN,
        arguments: {
          'session_id': item.id,
          'maintenance': true,
        },
      ),
    );
  }

  Future<void> _openDrawer(BuildContext context) async {
    var openingBalance = '0';
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('فتح صندوق الصيانة اليومي'),
        content: TextField(
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => openingBalance = value,
          onSubmitted: (value) => Navigator.pop(
            dialogContext,
            double.tryParse(value.trim()) ?? 0,
          ),
          decoration: const InputDecoration(
            labelText: 'رصيد الافتتاح',
            hintText: '0',
            suffixText: 'شيكل',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(openingBalance.trim()) ?? 0,
            ),
            child: const Text('فتح الصندوق'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await controller.openMaintenanceDailySession(openingBalance: amount);
    await _load();
  }
}
