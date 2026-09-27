// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../../data/models/main_dashboard_mata_model.dart';
import 'dashboard_design_tokens.dart';
import 'dashboard_section_header.dart';

class BuildStatisticsCards extends StatelessWidget {
  const BuildStatisticsCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminDashboardController>(builder: (controller) {
      final data = controller.mainDashboardDataModel;
      final badges = data?.dashboardBadges ?? const <String, int>{};
      final attentionItems = _buildAttentionItems(badges);
      final alertsCount = attentionItems.fold<int>(
        0,
        (total, item) => total + item.count,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alertsCount > 0) ...[
            _DashboardAttentionCard(
              items: attentionItems,
              total: alertsCount,
              onTap: () => _showAttentionSheet(context, attentionItems),
            ),
            SizedBox(height: DashboardDesignTokens.upperSectionSpacing.h),
          ],
          const DashboardSectionHeader(
            title: 'نظرة سريعة',
            icon: Icons.bar_chart_rounded,
          ),
          SizedBox(height: 10.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 320 ? 4 : 2;
              return GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: DashboardDesignTokens.cardSpacing.h,
                crossAxisSpacing: DashboardDesignTokens.cardSpacing.w,
                childAspectRatio: columns == 4 ? 1.02 : 1.75,
                children: [
                  _OverviewItem(
                    title: 'لنا',
                    value: data?.totalDebtsOwedToUs,
                    icon: Icons.north_rounded,
                    accent: DashboardDesignTokens.success,
                    onTap: () => _showDebtSummary(context,
                        data?.debtSummary ?? const DashboardDebtSummary()),
                  ),
                  _OverviewItem(
                    title: 'علينا',
                    value: data?.totalDebtsWeOwe,
                    icon: Icons.south_rounded,
                    accent: DashboardDesignTokens.danger,
                    onTap: () => _showDebtSummary(context,
                        data?.debtSummary ?? const DashboardDebtSummary()),
                  ),
                  _OverviewItem(
                    title: 'المصاريف',
                    value: data?.totalExpenses,
                    icon: Icons.receipt_long_outlined,
                    accent: DashboardDesignTokens.primary,
                  ),
                  _OverviewItem(
                    title: 'المنتجات',
                    value: data?.totalProducts,
                    icon: Icons.view_in_ar_outlined,
                    accent: DashboardDesignTokens.info,
                    showCurrency: false,
                  ),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

class _DashboardAttentionCard extends StatelessWidget {
  const _DashboardAttentionCard({
    required this.items,
    required this.total,
    required this.onTap,
  });

  final List<_AttentionItem> items;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final visibleItems = items.take(3).toList(growable: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesignTokens.cardRadius.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(13.w, 9.h, 13.w, 8.h),
          decoration: BoxDecoration(
            color: dark
                ? DashboardDesignTokens.darkSurface
                : const Color(0xFFFFFBFB),
            borderRadius:
                BorderRadius.circular(DashboardDesignTokens.cardRadius.r),
            border: Border.all(
              color: DashboardDesignTokens.danger.withValues(
                alpha: dark ? .32 : .20,
              ),
            ),
            boxShadow: DashboardDesignTokens.shadowFor(dark, quiet: true),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color:
                          DashboardDesignTokens.danger.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: DashboardDesignTokens.danger,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$total إجراء يحتاج متابعتك',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardDesignTokens.textPrimaryFor(dark),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardDesignTokens.danger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'فوري',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      color: DashboardDesignTokens.textSecondaryFor(dark),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12.sp,
                    color: DashboardDesignTokens.danger,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 7.w,
                  runSpacing: 6.h,
                  children: visibleItems
                      .map(
                        (item) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardDesignTokens.danger.withValues(
                              alpha: dark ? .12 : .045,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: DashboardDesignTokens.danger.withValues(
                                alpha: .13,
                              ),
                            ),
                          ),
                          child: Text(
                            '${item.count} ${item.shortTitle}',
                            style: TextStyle(
                              color: dark
                                  ? DashboardDesignTokens.darkTextPrimary
                                  : const Color(0xFF9E2638),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem(
      {required this.title,
      required this.value,
      required this.icon,
      required this.accent,
      this.onTap,
      this.showCurrency = true});
  final String title;
  final String? value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool showCurrency;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final parsed = double.tryParse(value ?? '');
    final formatted =
        parsed == null ? '—' : intl.NumberFormat('#,##0.##').format(parsed);
    return Material(
      color: DashboardDesignTokens.surfaceFor(dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardDesignTokens.cardRadius.r),
        side: BorderSide(color: DashboardDesignTokens.borderFor(dark)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesignTokens.cardRadius.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: DashboardDesignTokens.textPrimaryFor(dark),
                          fontSize: 8.5.sp,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    width: 30.r,
                    height: 30.r,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? .16 : .09),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, size: 18.sp, color: accent),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$formatted${showCurrency && parsed != null ? ' ₪' : ''}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: DashboardDesignTokens.textPrimaryFor(dark),
                      ),
                    ),
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

class _AttentionItem {
  const _AttentionItem({
    required this.title,
    required this.shortTitle,
    required this.count,
    required this.icon,
    required this.route,
  });

  final String title;
  final String shortTitle;
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
                        intl.NumberFormat('#,##0.##').format(total.receivable),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: 76.w,
                      child: Text(
                        intl.NumberFormat('#,##0.##').format(total.payable),
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

List<_AttentionItem> _buildAttentionItems(Map<String, int> badges) {
  int badge(String key) => badges[key] ?? 0;
  return <_AttentionItem>[
    _AttentionItem(
      title: 'مبيعات معلّقة',
      shortTitle: 'مبيعات معلّقة',
      count: badge('sales'),
      icon: Icons.pending_actions_rounded,
      route: AppRoutes.SALESSCREEN,
    ),
    _AttentionItem(
      title: 'صيانة غير مسلّمة',
      shortTitle: 'صيانة غير مسلّمة',
      count: badge('maintenance'),
      icon: Icons.home_repair_service_outlined,
      route: AppRoutes.MAINTENANCESCREEN,
    ),
    _AttentionItem(
      title: 'مهام بحاجة مراجعة',
      shortTitle: 'مهام للمراجعة',
      count: badge('employee_tasks_waiting_review'),
      icon: Icons.fact_check_outlined,
      route: AppRoutes.EMPLOYEETASKSSCREEN,
    ),
    _AttentionItem(
      title: 'طلبات السلف',
      shortTitle: 'طلبات سلف',
      count: badge('employee_loan_orders_pending'),
      icon: Icons.payments_outlined,
      route: AppRoutes.EMPLOYEESECTIONSCREEN,
    ),
    _AttentionItem(
      title: 'طلبات الأوفر تايم',
      shortTitle: 'طلبات أوفر تايم',
      count: badge('employee_overtime_orders_pending'),
      icon: Icons.more_time_rounded,
      route: AppRoutes.EMPLOYEESECTIONSCREEN,
    ),
    _AttentionItem(
      title: 'إغلاق صندوق المبيعات',
      shortTitle: 'إغلاقات مبيعات',
      count: badge('sales_daily_closing_pending'),
      icon: Icons.point_of_sale_outlined,
      route: AppRoutes.SALESDAILYHISTORYSCREEN,
    ),
    _AttentionItem(
      title: 'إغلاق صندوق الصيانة',
      shortTitle: 'إغلاقات صيانة',
      count: badge('maintenance_daily_closing_pending'),
      icon: Icons.home_repair_service_outlined,
      route: AppRoutes.MAINTENANCESCREEN,
    ),
    _AttentionItem(
      title: 'شيكات واردة مستحقة',
      shortTitle: 'شيكات واردة',
      count: badge('checks_incoming_red') + badge('checks_incoming_yellow'),
      icon: Icons.south_west_rounded,
      route: AppRoutes.CHECKSSCREEN,
    ),
    _AttentionItem(
      title: 'شيكات صادرة مستحقة',
      shortTitle: 'شيكات صادرة',
      count: badge('checks_outgoing_red') + badge('checks_outgoing_yellow'),
      icon: Icons.north_east_rounded,
      route: AppRoutes.CHECKSSCREEN,
    ),
  ].where((item) => item.count > 0).toList(growable: false);
}
