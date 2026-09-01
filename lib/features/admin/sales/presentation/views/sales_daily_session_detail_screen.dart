import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';
import '../../../../../routes/app_routes.dart';
import '../../../maintenance/data/repositories/maintenance_implement.dart';
import '../widgets/sales_daily_session_orders_log.dart';
import '../widgets/sales_daily_session_sales_log.dart';
import '../widgets/sales_daily_ui_widgets.dart';
import '../widgets/sales_skeleton_widgets.dart';

class SalesDailySessionDetailScreen extends StatefulWidget {
  const SalesDailySessionDetailScreen({Key? key}) : super(key: key);

  @override
  State<SalesDailySessionDetailScreen> createState() =>
      _SalesDailySessionDetailScreenState();
}

class _SalesDailySessionDetailScreenState
    extends State<SalesDailySessionDetailScreen> {
  bool _loading = true;
  String? _error;
  DailySessionDetailModel? _detail;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final args = Get.arguments;
    _maintenanceMode = args is Map && args['maintenance'] == true;
    if (args is DailySessionDetailModel) {
      setState(() {
        _detail = args;
        _loading = false;
      });
      return;
    }

    final rawId = args is Map ? args['session_id'] : args;
    final sessionId = rawId is int ? rawId : int.tryParse('$rawId');
    if (sessionId == null) {
      setState(() {
        _loading = false;
        _error = 'error'.tr;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final DailySessionDetailModel detail;
      if (_maintenanceMode) {
        detail = await Get.find<MaintenanceImplement>()
            .maintenanceDatasource
            .getDailySessionDetail(sessionId);
      } else {
        AppDependencyRegistry.ensureSales();
        final ds = Get.find<SalesDatasource>();
        detail = await ds.getDailySessionDetail(sessionId);
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: CustomAppBar(
        title: _maintenanceMode
            ? 'تفاصيل جلسة صندوق الصيانة'
            : 'تفاصيل الجلسة اليومية',
        action: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SalesDailySessionDetailSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              AppButton(text: 'tryAgain'.tr, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(child: Text('noData'.tr));
    }

    final session = detail.session;

    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      children: [
        _SessionHero(detail: detail, maintenanceMode: _maintenanceMode),
        SizedBox(height: 10.h),
        _SessionMetrics(detail: detail, maintenanceMode: _maintenanceMode),
        if (session.status == 'open' ||
            session.status == 'closing_requested') ...[
          SizedBox(height: 10.h),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: session.status == 'closing_requested'
                  ? Colors.orange.shade800
                  : AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: Icon(session.status == 'closing_requested'
                ? Icons.fact_check_outlined
                : Icons.lock_outline_rounded),
            label: Text(session.status == 'closing_requested'
                ? 'مراجعة طلب الإغلاق وإغلاق الجلسة'
                : 'إغلاق الجلسة اليومية'),
            onPressed: () async {
              await Get.toNamed(
                _maintenanceMode
                    ? AppRoutes.MAINTENANCEDAILYCLOSESCREEN
                    : AppRoutes.SALESDAILYCLOSESCREEN,
                arguments: session.id,
              );
              await _load();
            },
          ),
        ],
        const SalesDailySectionTitle(title: 'الأرصدة حسب العملة'),
        SalesDailyCurrencyTable(currencies: detail.currencies),
        if (session.sessionType == 'sales_orders') ...[
          const SalesDailySectionTitle(title: 'طلبيات الجلسة'),
          SalesDailySessionOrdersLog(orders: detail.salesOrders),
        ] else ...[
          SalesDailySectionTitle(
            title: _maintenanceMode
                ? 'طلبات وفواتير الصيانة في الجلسة'
                : 'فواتير الجلسة',
          ),
          SalesDailySessionSalesLog(
            instantSales: detail.instantSales,
            profitSales: detail.profitSales,
            maintenanceMode: _maintenanceMode,
          ),
        ],
        if (detail.closingRequests.isNotEmpty) ...[
          SalesDailySectionTitle(title: 'salesDailyClosingHistory'.tr),
          ...detail.closingRequests.map(
            (request) => SalesDailyClosingTile(request: request),
          ),
        ],
      ],
    );
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({required this.detail, required this.maintenanceMode});
  final DailySessionDetailModel detail;
  final bool maintenanceMode;

  @override
  Widget build(BuildContext context) {
    final session = detail.session;
    final open = session.status == 'open';
    final pending = session.status == 'closing_requested';
    final color = open
        ? const Color(0xFF059669)
        : pending
            ? Colors.orange.shade800
            : Colors.blueGrey;
    final type = maintenanceMode
        ? 'جلسة صندوق الصيانة اليومية'
        : session.sessionType == 'sales_orders'
            ? 'جلسة الطلبيات اليومية'
            : 'جلسة المبيعات اليومية';
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF12304A),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              maintenanceMode
                  ? Icons.build_circle_outlined
                  : session.sessionType == 'sales_orders'
                      ? Icons.inventory_2_outlined
                      : Icons.point_of_sale_outlined,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900)),
              Text('رقم الجلسة #${session.id}',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color),
            ),
            child: Text(
                open
                    ? 'مفتوحة'
                    : pending
                        ? 'بانتظار الإغلاق'
                        : 'مغلقة',
                style: TextStyle(
                    color: open || pending ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.sp)),
          ),
        ]),
        SizedBox(height: 14.h),
        Wrap(spacing: 14.w, runSpacing: 8.h, children: [
          _meta(Icons.person_outline, session.employeeName ?? 'غير محدد'),
          _meta(Icons.calendar_today_outlined, session.businessDate),
          if ((session.openedAt ?? '').isNotEmpty)
            _meta(Icons.login_rounded, 'فتحت ${_dateTime(session.openedAt!)}'),
          if ((session.closedAt ?? '').isNotEmpty)
            _meta(
                Icons.logout_rounded, 'أغلقت ${_dateTime(session.closedAt!)}'),
        ]),
      ]),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15.sp),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
        ],
      );

  String _dateTime(String value) =>
      value.length >= 16 ? value.substring(0, 16) : value;
}

class _SessionMetrics extends StatelessWidget {
  const _SessionMetrics({required this.detail, required this.maintenanceMode});
  final DailySessionDetailModel detail;
  final bool maintenanceMode;

  @override
  Widget build(BuildContext context) {
    final orders = detail.session.sessionType == 'sales_orders';
    final balance =
        detail.currencies.fold<double>(0, (sum, row) => sum + row.boxBalance);
    final sales = detail.currencies
        .fold<double>(0, (sum, row) => sum + row.salesCollected);
    return Row(children: [
      _metric(
          'الرصيد', '${balance.toStringAsFixed(2)} ₪', Icons.wallet_outlined),
      SizedBox(width: 7.w),
      _metric(
          'المقبوض', '${sales.toStringAsFixed(2)} ₪', Icons.payments_outlined),
      SizedBox(width: 7.w),
      _metric(
        maintenanceMode
            ? 'طلبات الصيانة'
            : orders
                ? 'الطلبيات'
                : 'الفواتير',
        '${orders ? detail.salesOrdersCount : detail.instantSalesCount + detail.profitSalesCount}',
        Icons.receipt_long_outlined,
      ),
    ]);
  }

  Widget _metric(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFDDE5EA)),
          ),
          child: Column(children: [
            Icon(icon, size: 18.sp, color: AppColors.primaryColor),
            SizedBox(height: 4.h),
            Text(value,
                maxLines: 1,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600)),
          ]),
        ),
      );
}
