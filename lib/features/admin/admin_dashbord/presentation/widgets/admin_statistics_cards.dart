// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../../data/models/main_dashboard_mata_model.dart';

class BuildStatisticsCards extends StatelessWidget {
  const BuildStatisticsCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminDashboardController>(builder: (controller) {
      final data = controller.mainDashboardDataModel;
      final badges = data?.dashboardBadges ?? const <String, int>{};
      int badge(String key) => badges[key] ?? 0;
      final attentionItems = _buildAttentionItems(badges);
      final alertsCount = attentionItems.fold<int>(
        0,
        (total, item) => total + item.count,
      );
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (alertsCount > 0) ...[
          InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => _showAttentionSheet(context, attentionItems),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : const Color(0xFFFFF3F4),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5A67),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.priority_high_rounded,
                      color: Colors.white, size: 22.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('يحتاج متابعتك',
                            style: TextStyle(
                                fontSize: 14.sp, fontWeight: FontWeight.w800)),
                        Text('$alertsCount طلب أو حالة بحاجة إجراء',
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5)),
                      ]),
                ),
                Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15.sp, color: const Color(0xFFF36C21)),
              ]),
            ),
          ),
          SizedBox(height: 6.h),
        ],
        const _SectionHeading(
          title: 'نظرة سريعة',
        ),
        SizedBox(height: 5.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 320 ? 4 : 2;
            return GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 7.h,
              crossAxisSpacing: 7.w,
              childAspectRatio: columns == 4 ? 1.22 : 2.1,
              children: [
                _OverviewItem(
                  title: 'لنا',
                  value: data?.totalDebtsOwedToUs ?? '0',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF1677F2),
                  surface: const Color(0xFFEAF3FF),
                  onTap: () => _showDebtSummary(context,
                      data?.debtSummary ?? const DashboardDebtSummary()),
                ),
                _OverviewItem(
                  title: 'علينا',
                  value: data?.totalDebtsWeOwe ?? '0',
                  icon: Icons.south_west_rounded,
                  accent: const Color(0xFFE53945),
                  surface: const Color(0xFFFFEFF0),
                  onTap: () => _showDebtSummary(context,
                      data?.debtSummary ?? const DashboardDebtSummary()),
                ),
                _OverviewItem(
                  title: 'المصاريف',
                  value: data?.totalExpenses ?? '0',
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFF6750E8),
                  surface: const Color(0xFFF2EFFF),
                ),
                _OverviewItem(
                  title: 'المنتجات',
                  value: data?.totalProducts ?? '0',
                  icon: Icons.inventory_2_outlined,
                  accent: const Color(0xFF16A464),
                  surface: const Color(0xFFEBFAF2),
                  showCurrency: false,
                ),
              ],
            );
          },
        ),
      ]);
    });
  }
}

class DashboardAttentionSection extends StatelessWidget {
  const DashboardAttentionSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminDashboardController>(builder: (controller) {
      final badges = controller.mainDashboardDataModel?.dashboardBadges ??
          const <String, int>{};
      final attentionItems = _buildAttentionItems(badges);
      if (attentionItems.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          _SectionHeading(
            title: 'أهم ما ينتظر المتابعة',
            trailing: TextButton(
              onPressed: () => _showAttentionSheet(context, attentionItems),
              child: const Text('عرض الكل'),
            ),
          ),
          SizedBox(height: 5.h),
          SizedBox(
            height: 68.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attentionItems.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) =>
                  _AttentionCard(item: attentionItems[index]),
            ),
          ),
        ],
      );
    });
  }
}

List<_AttentionItem> _buildAttentionItems(Map<String, int> badges) {
  int badge(String key) => badges[key] ?? 0;
  return <_AttentionItem>[
    _AttentionItem(
      title: 'مهام بحاجة مراجعة',
      count: badge('employee_tasks_waiting_review'),
      icon: Icons.fact_check_outlined,
      route: AppRoutes.EMPLOYEETASKSSCREEN,
    ),
    _AttentionItem(
      title: 'طلبات السلف',
      count: badge('employee_loan_orders_pending'),
      icon: Icons.payments_outlined,
      route: AppRoutes.EMPLOYEESECTIONSCREEN,
    ),
    _AttentionItem(
      title: 'طلبات الأوفر تايم',
      count: badge('employee_overtime_orders_pending'),
      icon: Icons.more_time_rounded,
      route: AppRoutes.EMPLOYEESECTIONSCREEN,
    ),
    _AttentionItem(
      title: 'إغلاق صندوق المبيعات',
      count: badge('sales_daily_closing_pending'),
      icon: Icons.point_of_sale_outlined,
      route: AppRoutes.SALESDAILYHISTORYSCREEN,
    ),
    _AttentionItem(
      title: 'إغلاق صندوق الصيانة',
      count: badge('maintenance_daily_closing_pending'),
      icon: Icons.home_repair_service_outlined,
      route: AppRoutes.MAINTENANCESCREEN,
    ),
    _AttentionItem(
      title: 'شيكات واردة مستحقة',
      count: badge('checks_incoming_red') + badge('checks_incoming_yellow'),
      icon: Icons.south_west_rounded,
      route: AppRoutes.CHECKSSCREEN,
    ),
    _AttentionItem(
      title: 'شيكات صادرة مستحقة',
      count: badge('checks_outgoing_red') + badge('checks_outgoing_yellow'),
      icon: Icons.north_east_rounded,
      route: AppRoutes.CHECKSSCREEN,
    ),
  ].where((item) => item.count > 0).toList(growable: false);
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem(
      {required this.title,
      required this.value,
      required this.icon,
      required this.accent,
      required this.surface,
      this.onTap,
      this.showCurrency = true});
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;
  final bool showCurrency;

  @override
  Widget build(BuildContext context) => Material(
        color: ThemeService.isDark.value ? AppColors.customGreyColor : surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
          side: BorderSide(color: accent.withValues(alpha: .22)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9.sp, fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(width: 3.w),
                    Icon(icon, size: 18.sp, color: accent),
                  ],
                ),
                Text(
                    '${NumberFormat('#,##0.##').format(double.tryParse(value) ?? 0)}${showCurrency ? ' ₪' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.operationalNavy)),
              ],
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.operationalNavy)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 142.w,
        child: Material(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(
              color: AppColors.operationalPurple.withValues(alpha: .13),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () => Get.toNamed(item.route),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              child: Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(item.icon,
                        color: const Color(0xFFE53945), size: 19.sp),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.count}',
                            style: TextStyle(
                                color: const Color(0xFFE53945),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900)),
                        Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.sp, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 12.sp, color: AppColors.customGreyColor5),
                ],
              ),
            ),
          ),
        ),
      );
}

class _AttentionItem {
  const _AttentionItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.route,
  });

  final String title;
  final int count;
  final IconData icon;
  final String route;
}

void _showAttentionSheet(
  BuildContext context,
  List<_AttentionItem> items,
) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * .78),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 10.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF36C21).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: const Color(0xFFF36C21),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يحتاج متابعتك',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'اضغط على أي بند لمراجعته',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: Get.back, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(12.r),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 7.h),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11.r),
                      side: BorderSide(
                        color:
                            AppColors.operationalPurple.withValues(alpha: .14),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11.r),
                      onTap: () {
                        Get.back();
                        Get.toNamed(item.route);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36.r,
                              height: 36.r,
                              decoration: BoxDecoration(
                                color: AppColors.operationalPurple
                                    .withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(9.r),
                              ),
                              child: Icon(
                                item.icon,
                                color: AppColors.operationalPurple,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 9.w),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              constraints: BoxConstraints(minWidth: 28.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.count > 99 ? '99+' : '${item.count}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14.sp,
                              color: AppColors.operationalPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

void _showDebtSummary(BuildContext context, DashboardDebtSummary summary) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * .82),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 10.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryColor, size: 20.sp),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Text(
                      'ملخص الديون',
                      style: TextStyle(
                          fontSize: 17.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                      onPressed: Get.back, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(12.r),
                children: [
                  _DebtGroupCard(
                    title: 'العملاء',
                    icon: Icons.groups_2_outlined,
                    totals: summary.customers,
                  ),
                  _DebtGroupCard(
                    title: 'الموردون',
                    icon: Icons.local_shipping_outlined,
                    totals: summary.sellers,
                  ),
                  _DebtGroupCard(
                    title: 'الخاص',
                    icon: Icons.lock_person_outlined,
                    totals: summary.privatePeople,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _DebtGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, DashboardDebtCurrencyTotal> totals;

  const _DebtGroupCard({
    required this.title,
    required this.icon,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    const currencies = ['شيكل', 'دولار', 'دينار'];
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      color:
          ThemeService.isDark.value ? AppColors.customGreyColor4 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 19.sp),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w800)),
                ),
                SizedBox(
                  width: 76.w,
                  child: Text('لنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 76.w,
                  child: Text('علينا',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Divider(height: 16.h),
            ...currencies.map((currency) {
              final total =
                  totals[currency] ?? const DashboardDebtCurrencyTotal();
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(currency,
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      width: 76.w,
                      child: Text(
                        NumberFormat('#,##0.##').format(total.receivable),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: 76.w,
                      child: Text(
                        NumberFormat('#,##0.##').format(total.payable),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
