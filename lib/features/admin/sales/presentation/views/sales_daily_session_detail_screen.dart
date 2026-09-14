import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/theme_service.dart';
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final sessionType = _detail?.session.sessionType;
    final title = _maintenanceMode
        ? 'حركات صندوق الصيانة'
        : sessionType == 'sales_orders'
            ? 'حركات صندوق الطلبيات'
            : 'حركات صندوق المبيعات';
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF17171F)
          : const Color(0xFFF4F7F9),
      appBar: CustomAppBar(
        title: title,
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
    final query = _query.trim().toLowerCase();
    final filteredInstant = detail.instantSales.where((row) {
      if (query.isEmpty) return true;
      return '${row.label} ${row.invoiceNumber ?? ''} ${row.serialNumber ?? ''} ${row.buyerName ?? ''} ${row.createdByName ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final filteredProfit = detail.profitSales.where((row) {
      if (query.isEmpty) return true;
      return '${row.label} ${row.invoiceNumber ?? ''} ${row.buyerName ?? ''} ${row.createdByName ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final filteredOrders = detail.salesOrders.where((row) {
      if (query.isEmpty) return true;
      return '${row.serialNumber ?? ''} ${row.customerName ?? ''} ${row.createdByName ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final movementCount = session.sessionType == 'sales_orders'
        ? filteredOrders.length
        : filteredInstant.length + filteredProfit.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      children: [
        _SessionHero(detail: detail, maintenanceMode: _maintenanceMode),
        SizedBox(height: 10.h),
        _BoxMovementsScope(
          label: _maintenanceMode
              ? 'حركات صندوق الصيانة فقط'
              : session.sessionType == 'sales_orders'
                  ? 'حركات صندوق الطلبيات فقط'
                  : 'حركات صندوق المبيعات فقط',
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'ابحث في الحركات',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: ThemeService.isDark.value
                ? const Color(0xFF242430)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        _SessionMetrics(detail: detail),
        if (session.status == 'closed' &&
            detail.currencies.any((row) => row.hasClosingSnapshot)) ...[
          SizedBox(height: 10.h),
          _ClosingSummary(detail: detail),
        ],
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
        if (session.sessionType == 'sales_orders') ...[
          SalesDailySectionTitle(title: 'حركات الطلبيات ($movementCount)'),
          SalesDailySessionOrdersLog(orders: filteredOrders),
        ] else ...[
          SalesDailySectionTitle(
            title:
                '${_maintenanceMode ? 'حركات الصيانة' : 'حركات المبيعات'} ($movementCount)',
          ),
          SalesDailySessionSalesLog(
            instantSales: filteredInstant,
            profitSales: filteredProfit,
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

class _BoxMovementsScope extends StatelessWidget {
  const _BoxMovementsScope({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined,
              color: AppColors.primaryColor, size: 21.sp),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
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
          _meta(Icons.person_outline,
              'صاحب الجلسة: ${session.employeeName ?? 'غير محدد'}'),
          _meta(Icons.person_pin_outlined,
              'فتحها: ${session.openedByName ?? session.employeeName ?? 'غير محدد'}'),
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
  const _SessionMetrics({required this.detail});
  final DailySessionDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final primaryCurrency =
        detail.currencies.firstWhereOrNull((row) => row.currency == 'شيكل') ??
            (detail.currencies.isEmpty ? null : detail.currencies.first);
    final opening = primaryCurrency?.openingFloat ?? 0;
    final balance = primaryCurrency?.systemBalance ?? 0;
    final sales = primaryCurrency?.salesCollected ?? 0;
    return Row(children: [
      _metric('رصيد الافتتاح', '${opening.toStringAsFixed(2)} ₪',
          Icons.account_balance_wallet_outlined),
      SizedBox(width: 7.w),
      _metric('المقبوض اليوم', '${sales.toStringAsFixed(2)} ₪',
          Icons.payments_outlined),
      SizedBox(width: 7.w),
      _metric('الرصيد الحالي', '${balance.toStringAsFixed(2)} ₪',
          Icons.wallet_outlined),
    ]);
  }

  Widget _metric(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? const Color(0xFF242430)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ThemeService.isDark.value
                  ? const Color(0xFF3B3B49)
                  : const Color(0xFFDDE5EA),
            ),
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

class _ClosingSummary extends StatelessWidget {
  const _ClosingSummary({required this.detail});

  final DailySessionDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final currency =
        detail.currencies.firstWhereOrNull((row) => row.currency == 'شيكل') ??
            detail.currencies.firstWhereOrNull((row) => row.hasClosingSnapshot);
    if (currency == null || !currency.hasClosingSnapshot) {
      return const SizedBox.shrink();
    }

    final varianceColor = currency.closingVariance.abs() <= 0.01
        ? const Color(0xFF059669)
        : Colors.red.shade700;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color:
            ThemeService.isDark.value ? const Color(0xFF242430) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeService.isDark.value
              ? const Color(0xFF3B3B49)
              : const Color(0xFFDDE5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  size: 19.sp, color: AppColors.primaryColor),
              SizedBox(width: 7.w),
              Text(
                'ملخص الإغلاق',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _value(
                  'المعدود فعليًا',
                  currency.closingPhysicalCount,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _value(
                  'الفرق',
                  currency.closingVariance,
                  valueColor: varianceColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _value(
                  'فكة اليوم التالي',
                  currency.closingFloatToKeep,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _value(
                  'تم ترحيله',
                  currency.closingAmountToTransfer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _value(String label, double amount, {Color? valueColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? Colors.black12
            : const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600)),
          SizedBox(height: 3.h),
          Text(
            '${amount.toStringAsFixed(2)} ₪',
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
