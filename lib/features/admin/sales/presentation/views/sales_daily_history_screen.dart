import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../maintenance/presentation/binding/maintenance_binding.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
import '../../../maintenance/presentation/views/maintenance_daily_history_screen.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_daily_history_controller.dart';
import '../controllers/sales_daily_admin_controller.dart';
import 'sales_daily_admin_screen.dart';
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
    selectedType = requested == 'maintenance'
        ? 'maintenance'
        : requested == 'sales_orders'
            ? 'sales_orders'
            : 'instant_sales';
    AppDependencyRegistry.ensureChecks();
    AppDependencyRegistry.ensureBoxes();
    AppDependencyRegistry.ensureMaintenance();
    if (!Get.isRegistered<MaintenanceController>() &&
        !Get.isPrepared<MaintenanceController>()) {
      MaintenanceBinding().dependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedType == 'maintenance') {
      return Scaffold(
        appBar: const CustomAppBar(title: 'الجلسات اليومية', action: false),
        body: MaintenanceDailyHistoryScreen(
          embedded: true,
          drawerSelector: _DrawerTypeSelector(
            selectedType: selectedType,
            onChanged: (value) => setState(() => selectedType = value),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'الجلسات اليومية',
        action: false,
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
        if (_shouldAutoOpen() && _shouldOfferOpening()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openSelectedDrawer(context);
          });
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 18.h),
            children: [
              _ActiveDrawerBanner(
                session: active,
                type: selectedType,
                canOpen: _shouldOfferOpening(),
                onOpen: () => _openSelectedDrawer(context),
              ),
              SizedBox(height: 7.h),
              _DrawerTypeSelector(
                selectedType: selectedType,
                onChanged: (value) => setState(() => selectedType = value),
              ),
              SizedBox(height: 7.h),
              SalesDailySummaryStrip(
                openCount: today.where((item) => item.isOpen).length,
                pendingCount:
                    today.where((item) => item.isClosingRequested).length,
                closedCount:
                    today.where((item) => item.status == 'closed').length,
              ),
              if (sales?.pendingDailyClosingRequests.isNotEmpty == true) ...[
                SizedBox(height: 7.h),
                _InlineClosingRequests(
                  sales: sales!,
                  sessionType: selectedType,
                ),
              ],
              if (sales?.pendingSalesCancellationRequests.isNotEmpty ==
                  true) ...[
                SizedBox(height: 7.h),
                _InlineCancellationRequests(sales: sales!),
              ],
              SizedBox(height: 7.h),
              _ListModeSelector(
                showHistory: showHistory,
                onChanged: (value) => setState(() => showHistory = value),
              ),
              SizedBox(height: 7.h),
              if (list.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: const ShowNoData(),
                )
              else
                ...list.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
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
    if (sales == null) return false;
    final payload = selectedType == 'sales_orders'
        ? sales!.salesOrdersDailySessionPayload.value
        : sales!.dailySessionPayload.value;
    return payload?.canRequestOpen == true || payload?.needsManualOpen == true;
  }

  bool _shouldAutoOpen() {
    final args = Get.arguments;
    return args is Map && args['openDrawer'] == true;
  }

  Future<void> _openSelectedDrawer(BuildContext context) async {
    final args = Get.arguments;
    final autoOpen = _shouldAutoOpen();
    if (autoOpen && args is Map) args['openDrawer'] = false;
    await SalesDailyStatusBar(
      salesOrders: selectedType == 'sales_orders',
      onOpened: _continueAfterOpening,
    ).openDrawer(context);
  }

  Future<void> _continueAfterOpening() async {
    await _refresh();
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
  const _InlineClosingRequests({
    required this.sales,
    required this.sessionType,
  });

  final SalesController sales;
  final String sessionType;

  @override
  Widget build(BuildContext context) {
    final requests = sales.pendingDailyClosingRequests
        .where((request) => request.sessionType == sessionType)
        .toList();
    if (requests.isEmpty) return const SizedBox.shrink();
    final drawerName =
        sessionType == 'sales_orders' ? 'صندوق الطلبيات' : 'صندوق المبيعات';
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
                'طلبات إغلاق $drawerName (${requests.length})',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ...requests.map(
            (request) => Container(
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
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            sales.rejectDailyClosingInline(request.id),
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.red),
                        label: const Text('رفض',
                            style: TextStyle(color: Colors.red)),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            sales.approveDailyClosingInline(request),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('موافقة'),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showClosingDetails(context, request),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('التفاصيل والترحيل'),
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

  Future<void> _showClosingDetails(
    BuildContext context,
    DailyClosingRequestModel request,
  ) async {
    if (!Get.isRegistered<SalesDailyAdminController>()) {
      SalesDailyAdminBinding().dependencies();
    }
    final admin = Get.find<SalesDailyAdminController>();
    await admin.loadAll();
    if (!context.mounted) return;
    await SalesDailyClosingRequestsList.showClosingSheet(
      context,
      admin,
      request,
    );
    await sales.loadDailySession();
  }
}

class _InlineCancellationRequests extends StatelessWidget {
  const _InlineCancellationRequests({required this.sales});

  final SalesController sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: Colors.red.shade700, size: 19.sp),
              SizedBox(width: 6.w),
              Text(
                'طلبات إلغاء الفواتير (${sales.pendingSalesCancellationRequests.length})',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          ...sales.pendingSalesCancellationRequests.map(
            (request) => Container(
              margin: EdgeInsets.only(top: 5.h),
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9.r),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.saleType == 'instant' ? 'بيع فوري' : 'بيع ربحي'} #${request.saleId} — ${request.employeeName ?? '—'}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          request.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'رفض',
                    onPressed: () => sales.reviewSalesCancellationInline(
                      request,
                      approve: false,
                    ),
                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'موافقة',
                    onPressed: () => sales.reviewSalesCancellationInline(
                      request,
                      approve: true,
                    ),
                    icon: const Icon(Icons.check_rounded, color: Colors.green),
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

class _ActiveDrawerBanner extends StatelessWidget {
  const _ActiveDrawerBanner({
    required this.session,
    required this.type,
    required this.canOpen,
    required this.onOpen,
  });

  final DailySessionSummaryModel? session;
  final String type;
  final bool canOpen;
  final VoidCallback onOpen;

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
                  orders
                      ? Icons.local_shipping_outlined
                      : Icons.account_balance_wallet_outlined,
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
                      orders
                          ? 'صندوق الطلبيات اليومي'
                          : 'صندوق المبيعات اليومي',
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
          Text('الرصيد الحالي',
              style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
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
            SizedBox(height: 7.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
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
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ] else if (canOpen) ...[
            SizedBox(height: 7.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onOpen,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(orders
                    ? 'فتح صندوق الطلبيات اليومي'
                    : 'فتح صندوق المبيعات اليومي'),
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
        SizedBox(width: 8.w),
        Expanded(
          child: _TypeButton(
            label: 'صندوق الصيانة',
            icon: Icons.build_circle_outlined,
            selected: selectedType == 'maintenance',
            onTap: () => onChanged('maintenance'),
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
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
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
                size: 17.sp,
                color: selected ? AppColors.primaryColor : Colors.grey),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
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
      selected: {showHistory},
      onSelectionChanged: (value) => onChanged(value.first),
      showSelectedIcon: false,
    );
  }
}
