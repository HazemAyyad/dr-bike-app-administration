import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_daily_history_controller.dart';
import '../widgets/sales_daily_ui_widgets.dart';
import '../widgets/sales_skeleton_widgets.dart';
import '../widgets/sales_daily_status_bar.dart';
import '../../../../../routes/app_routes.dart';

class SalesDailyHistoryScreen extends StatefulWidget {
  const SalesDailyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SalesDailyHistoryScreen> createState() =>
      _SalesDailyHistoryScreenState();
}

class _SalesDailyHistoryScreenState extends State<SalesDailyHistoryScreen> {
  SalesDailyHistoryController get controller =>
      Get.find<SalesDailyHistoryController>();

  SalesController? get sales =>
      Get.isRegistered<SalesController>() ? Get.find<SalesController>() : null;

  late String selectedType;
  bool showHistory = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final requested = args is Map ? '${args['sessionType'] ?? ''}' : '';
    selectedType =
        requested == 'sales_orders' ? 'sales_orders' : 'instant_sales';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'صناديق المبيعات اليومية',
        action: false,
        actions: [
          if (sales != null) _ClosingRequestsButton(sales: sales!),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const SalesDailyHistorySkeleton();
        }
        final overview = controller.todayOverview.value;
        if (overview == null) return const Center(child: ShowNoData());

        final today = overview.sessions
            .where((session) => session.sessionType == selectedType)
            .toList();
        final history = controller.historySessions
            .where((session) => session.sessionType == selectedType)
            .toList();
        final active = today.firstWhereOrNull(
              (session) => session.isOpen || session.isClosingRequested,
            ) ??
            (today.isEmpty ? null : today.first);
        final list = showHistory ? history : today;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
            children: [
              if (_shouldOfferOpening()) ...[
                SalesDailyStatusBar(
                  salesOrders: selectedType == 'sales_orders',
                  onOpened: _continueAfterOpening,
                  autoOpen: true,
                ),
                SizedBox(height: 10.h),
              ],
              _ActiveDrawerBanner(
                session: active,
                type: selectedType,
              ),
              SizedBox(height: 12.h),
              _DrawerTypeSelector(
                selectedType: selectedType,
                onChanged: (value) => setState(() => selectedType = value),
              ),
              SizedBox(height: 12.h),
              SalesDailySummaryStrip(
                openCount: overview.openCount,
                pendingCount: overview.closingRequestedCount,
                closedCount: overview.closedCount,
              ),
              if (sales?.pendingDailyClosingRequests.isNotEmpty == true) ...[
                SizedBox(height: 12.h),
                _InlineClosingRequests(sales: sales!),
              ],
              SizedBox(height: 12.h),
              _ListModeSelector(
                showHistory: showHistory,
                onChanged: (value) => setState(() => showHistory = value),
              ),
              SizedBox(height: 10.h),
              if (list.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 45.h),
                  child: const ShowNoData(),
                )
              else
                ...list.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: SalesDailySessionTile(
                      item: item,
                      onTap: () => controller.openSessionDetail(item.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      controller.loadAll(),
      if (sales != null) sales!.loadDailySession(),
    ]);
  }

  bool _shouldOfferOpening() {
    final args = Get.arguments;
    if (args is! Map || args['openDrawer'] != true || sales == null) {
      return false;
    }
    final payload = selectedType == 'sales_orders'
        ? sales!.salesOrdersDailySessionPayload.value
        : sales!.dailySessionPayload.value;
    return payload?.canRequestOpen == true || payload?.needsManualOpen == true;
  }

  Future<void> _continueAfterOpening() async {
    final args = Get.arguments;
    if (args is! Map) return;
    final route = '${args['returnRoute'] ?? ''}';
    if (route.isEmpty) return;
    final raw = args['returnArguments'];
    final item =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final routeArgs = <String, dynamic>{
      'isNewCheck': item['title'] == 'newCheck',
      'isPenaltyTitle': item['title'],
      'title': item['flowTitle'] ?? item['title'],
      if (item['freshInstantSale'] == 'true') 'freshInstantSale': true,
      if (item['saleKind'] != null) 'saleKind': item['saleKind'],
      if (item['freshSalesOrder'] == 'true') 'freshSalesOrder': true,
    };
    Get.offNamed(route, arguments: routeArgs);
  }
}

class _InlineClosingRequests extends StatelessWidget {
  const _InlineClosingRequests({required this.sales});

  final SalesController sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
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
                'طلبات إغلاق الصناديق (${sales.pendingDailyClosingRequests.length})',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...sales.pendingDailyClosingRequests.map(
            (request) => Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 6.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeName ?? '—',
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'تاريخ الصندوق: ${request.businessDate ?? '—'}\n'
                    'المبيعات: ${request.instantSalesCount} — البيع الربحي: ${request.profitSalesCount}',
                    style:
                        TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 7.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            sales.rejectDailyClosingInline(request.id),
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.red),
                        label: const Text('رفض',
                            style: TextStyle(color: Colors.red)),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            sales.approveDailyClosingInline(request),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('موافقة'),
                      ),
                      TextButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.SALESDAILYADMINSCREEN,
                          arguments: {'initialTab': 1},
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('تفاصيل الترحيل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingRequestsButton extends StatelessWidget {
  const _ClosingRequestsButton({required this.sales});

  final SalesController sales;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = sales.pendingDailyClosingCount.value;
      return Tooltip(
        message: 'طلبات إغلاق الصناديق',
        child: IconButton(
          onPressed: () async {
            await Get.toNamed(
              AppRoutes.SALESDAILYADMINSCREEN,
              arguments: {'initialTab': 1},
            );
            await sales.loadDailySession();
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.pending_actions_outlined),
          ),
        ),
      );
    });
  }
}

class _ActiveDrawerBanner extends StatelessWidget {
  const _ActiveDrawerBanner({required this.session, required this.type});

  final DailySessionSummaryModel? session;
  final String type;

  @override
  Widget build(BuildContext context) {
    final orders = type == 'sales_orders';
    final closing = session?.isClosingRequested ?? false;
    final open = session?.isOpen ?? false;
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
    final shekel = session?.currencies
        .firstWhereOrNull((currency) => currency.currency == 'شيكل');
    final balance = shekel?.systemBalance ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: Icon(
                  orders
                      ? Icons.local_shipping_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orders
                          ? 'صندوق الطلبيات اليومي'
                          : 'صندوق المبيعات اليومي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
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
          SizedBox(height: 18.h),
          Text(
            '${balance.toStringAsFixed(2)} ₪',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Text('الرصيد الحالي',
              style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                    'فتحه: ${session?.employeeName ?? '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                  ),
                ),
                const Icon(Icons.schedule_outlined, color: Colors.white70),
                SizedBox(width: 4.w),
                Text(
                  _time(session?.openedAt),
                  style: TextStyle(color: Colors.white, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          if (session?.canClose == true) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                ),
                onPressed: () => Get.toNamed(
                  AppRoutes.SALESDAILYCLOSESCREEN,
                  arguments: session!.id,
                ),
                icon: const Icon(Icons.lock_clock_outlined),
                label: Text(
                  session!.isClosingRequested
                      ? 'طلب الإغلاق قيد المراجعة'
                      : 'تقديم طلب إغلاق الصندوق',
                ),
              ),
            ),
          ] else if (session?.isClosingRequested == true) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white54),
              ),
              child: const Text(
                'طلب الإغلاق قيد مراجعة الإدارة',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _time(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour >= 12 ? 'م' : 'ص'}';
  }
}

class _DrawerTypeSelector extends StatelessWidget {
  const _DrawerTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'صندوق المبيعات',
            icon: Icons.point_of_sale_outlined,
            selected: selectedType == 'instant_sales',
            onTap: () => onChanged('instant_sales'),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _TypeButton(
            label: 'صندوق الطلبيات',
            icon: Icons.local_shipping_outlined,
            selected: selectedType == 'sales_orders',
            onTap: () => onChanged('sales_orders'),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 19.sp,
                color: selected ? AppColors.primaryColor : Colors.grey),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color:
                      selected ? AppColors.primaryColor : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListModeSelector extends StatelessWidget {
  const _ListModeSelector({
    required this.showHistory,
    required this.onChanged,
  });

  final bool showHistory;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
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
      selected: {showHistory},
      onSelectionChanged: (value) => onChanged(value.first),
      showSelectedIcon: false,
    );
  }
}
