import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../../sales/data/models/daily_session_model.dart';
import '../../data/repositories/maintenance_implement.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDailyHistoryScreen extends StatefulWidget {
  const MaintenanceDailyHistoryScreen({Key? key}) : super(key: key);

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
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    _loadError = null;
    try {
      await controller.loadMaintenanceDailySession().timeout(
            const Duration(seconds: 15),
          );
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final history = await datasource
          .getDailySessionsHistory()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _today
        ..clear()
        ..addAll(history.where((item) => item.businessDate == today));
      _history
        ..clear()
        ..addAll(history);
    } on TimeoutException {
      _loadError = 'استغرق تحميل الصناديق وقتاً طويلاً';
    } catch (_) {
      _loadError = 'تعذر تحميل صناديق الصيانة';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DailySessionSummaryModel? get _active => _today.firstWhereOrNull(
        (item) => item.isOpen || item.isClosingRequested,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'صناديق الصيانة اليومية',
        action: false,
      ),
      body: _loading
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
                      _summaryStrip(),
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
                ),
    );
  }

  Widget _activeCard(BuildContext context) {
    final active = _active;
    final closing = active?.isClosingRequested == true;
    final open = active?.isOpen == true;
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
            ),
          ),
          SizedBox(height: 7.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 5.h,
            children: [
              if (controller.canRequestMaintenanceDailyOpen)
                _whiteAction(
                  icon: Icons.lock_open_rounded,
                  label: 'فتح الصندوق',
                  onTap: () => _openDrawer(context),
                ),
              if (controller.canRequestMaintenanceDailyClosing)
                _whiteAction(
                  icon: Icons.lock_clock_outlined,
                  label: 'إغلاق اليوم',
                  onTap: () async {
                    await Get.toNamed(AppRoutes.MAINTENANCEDAILYCLOSESCREEN);
                    await _load();
                  },
                ),
              if (userType == 'admin')
                _whiteAction(
                  icon: Icons.pending_actions_outlined,
                  label: 'طلبات الإغلاق',
                  onTap: () async {
                    await Get.toNamed(AppRoutes.MAINTENANCEDAILYADMINSCREEN);
                    await _load();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whiteAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: Colors.white38),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStrip() {
    final all = _history;
    return Row(
      children: [
        _summaryItem('مفتوح', all.where((e) => e.isOpen).length, Colors.green),
        SizedBox(width: 6.w),
        _summaryItem(
          'بانتظار الإغلاق',
          all.where((e) => e.isClosingRequested).length,
          Colors.orange,
        ),
        SizedBox(width: 6.w),
        _summaryItem(
          'مغلق',
          all.where((e) => e.status == 'closed').length,
          Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(fontSize: 9.5.sp)),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
            value: false, label: Text('اليوم'), icon: Icon(Icons.today)),
        ButtonSegment(
            value: true, label: Text('السجل'), icon: Icon(Icons.history)),
      ],
      selected: {_showHistory},
      onSelectionChanged: (value) => setState(() => _showHistory = value.first),
    );
  }

  Widget _sessionTile(BuildContext context, DailySessionSummaryModel item) {
    final color = item.isClosingRequested
        ? Colors.orange
        : item.isOpen
            ? Colors.green
            : Colors.blueGrey;
    final balance = item.currencies
            .firstWhereOrNull((row) => row.currency == 'شيكل')
            ?.systemBalance ??
        0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.10),
          child: Icon(Icons.build_outlined, color: color),
        ),
        title: Text(
          item.employeeName ?? 'صندوق صيانة',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item.businessDate} • ${_statusLabel(item.status)}\n'
          '${item.instantSalesCount} طلب صيانة',
        ),
        isThreeLine: true,
        trailing: Text(
          '${balance.toStringAsFixed(2)} ₪',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        onTap: () => _showDetails(context, item),
      ),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    DailySessionSummaryModel item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تفاصيل صندوق ${item.businessDate}',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 12.h),
              _detailRow('الموظف', item.employeeName ?? '—'),
              _detailRow('الحالة', _statusLabel(item.status)),
              _detailRow('طلبات الصيانة', '${item.instantSalesCount}'),
              _detailRow('وقت الفتح', item.openedAt ?? '—'),
              _detailRow('وقت الإغلاق', item.closedAt ?? '—'),
              SizedBox(height: 10.h),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed(
                    AppRoutes.DAILYBOXESSCREEN,
                    arguments: {'filter': 'maintenance', 'dedicated': true},
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('عرض الحركات والفواتير'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 7.h),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Future<void> _openDrawer(BuildContext context) async {
    final input = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('فتح صندوق الصيانة اليومي'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'رصيد الافتتاح',
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
              double.tryParse(input.text.trim()) ?? 0,
            ),
            child: const Text('فتح الصندوق'),
          ),
        ],
      ),
    );
    input.dispose();
    if (amount == null) return;
    await controller.openMaintenanceDailySession(openingBalance: amount);
    await _load();
  }

  String _statusLabel(String value) {
    if (value == 'open') return 'مفتوح';
    if (value == 'closing_requested') return 'بانتظار الإغلاق';
    if (value == 'closed') return 'مغلق';
    return value;
  }
}
