// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../../data/models/main_dashboard_mata_model.dart';
import 'stat_card.dart';

class BuildStatisticsCards extends StatelessWidget {
  const BuildStatisticsCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
      ),
      child: GetBuilder<AdminDashboardController>(
        builder: (controller) {
          return Column(
            children: [
              // الصف الأول: ديون لنا وديون علينا
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'debtsForUs',
                      icon: Icons.trending_up_rounded,
                      value: controller
                              .mainDashboardDataModel?.totalDebtsOwedToUs ??
                          '0',
                      subtitle: 'currency',
                      onTap: () => _showDebtSummary(
                        context,
                        controller.mainDashboardDataModel?.debtSummary ??
                            const DashboardDebtSummary(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      title: 'debtsOnUs',
                      icon: Icons.trending_down_rounded,
                      value:
                          controller.mainDashboardDataModel?.totalDebtsWeOwe ??
                              '0',
                      subtitle: 'currency',
                      onTap: () => _showDebtSummary(
                        context,
                        controller.mainDashboardDataModel?.debtSummary ??
                            const DashboardDebtSummary(),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _UpcomingChecksCard(
                      title: 'وارد',
                      icon: Icons.south_west_rounded,
                      color: AppColors.primaryColor,
                      checks: controller
                              .mainDashboardDataModel?.upcomingIncomingChecks ??
                          const [],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _UpcomingChecksCard(
                      title: 'صادر',
                      icon: Icons.north_east_rounded,
                      color: AppColors.primaryColor,
                      checks: controller
                              .mainDashboardDataModel?.upcomingOutgoingChecks ??
                          const [],
                    ),
                  ),
                ],
              ),
              // الصف الثاني: المنتجات والموظفين
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'products',
                      icon: Icons.inventory_2_outlined,
                      value: controller.mainDashboardDataModel?.totalProducts ??
                          '0',
                      subtitle: 'product',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GetBuilder<AdminDashboardController>(
                      builder: (_) {
                        return StatCard(
                          title: 'employees',
                          icon: Icons.groups_2_outlined,
                          value: controller
                                  .mainDashboardDataModel?.numberOfEmployees ??
                              '0',
                          subtitle: 'employee',
                        );
                      },
                    ),
                  ),
                ],
              ),
              // SizedBox(height: 8.w),
              // الصف الثالث: مهام منجزة ومهام غير منجزة
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'completedTasks',
                      icon: Icons.task_alt_rounded,
                      value: controller
                              .mainDashboardDataModel?.totalCompletedTasks ??
                          '0',
                      subtitle: 'task',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      title: 'uncompletedTasks',
                      icon: Icons.pending_actions_rounded,
                      value: controller
                              .mainDashboardDataModel?.totalIncompletedTasks ??
                          '0',
                      subtitle: 'task',
                    ),
                  ),
                ],
              ),
              // SizedBox(height: 8.w),
              // الصف الرابع: مصاريف (عرض كامل)
              StatCard(
                title: 'expenses',
                icon: Icons.payments_outlined,
                value: controller.mainDashboardDataModel?.totalExpenses ?? '0',
                subtitle: 'currency',
              ),
            ],
          );
        },
      ),
    );
  }
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

class _UpcomingChecksCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<DashboardCheckModel> checks;

  const _UpcomingChecksCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.checks,
  });

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final check in checks) {
      totals.update(check.currency, (value) => value + check.total,
          ifAbsent: () => check.total);
    }
    final summary = checks.isEmpty
        ? 'لا يوجد شيكات قادمة'
        : totals.entries
            .map((e) => '${NumberFormat('#,##0.##').format(e.value)} ${e.key}')
            .join(' | ');

    return GestureDetector(
      onTap: checks.isEmpty ? null : () => _showDetails(context),
      child: Container(
        margin: EdgeInsets.all(5.r),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          children: [
            Container(
              width: 29.r,
              height: 29.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 16.sp, color: color),
            ),
            SizedBox(width: 7.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 11.sp, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text('${checks.length}',
                            style: TextStyle(
                                color: color,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * .78),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(children: [
                  Icon(icon, color: color),
                  SizedBox(width: 8.w),
                  Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 17.sp, fontWeight: FontWeight.w800))),
                  IconButton(
                      onPressed: Get.back, icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(12.r),
                  itemCount: checks.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) => _CheckDetailsTile(
                    check: checks[index],
                    index: index + 1,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _CheckDetailsTile extends StatelessWidget {
  final DashboardCheckModel check;
  final int index;
  final Color color;
  const _CheckDetailsTile(
      {required this.check, required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    final date = check.dueDate == null
        ? '-'
        : DateFormat('yyyy/MM/dd').format(check.dueDate!);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 14.r,
                backgroundColor: color.withValues(alpha: .15),
                child: Text('$index',
                    style: TextStyle(color: color, fontSize: 11.sp))),
            SizedBox(width: 8.w),
            Expanded(
                child: Text(
                    '${NumberFormat('#,##0.##').format(check.total)} ${check.currency}',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor))),
            Text('الاستحقاق: $date', style: TextStyle(fontSize: 11.sp)),
          ]),
          SizedBox(height: 8.h),
          Text('رقم الشيك: ${check.checkId}'),
          Text('البنك: ${check.bankName}'),
          Text('صاحب الشيك: ${check.personName}'),
          if (check.notes.isNotEmpty) Text('ملاحظات: ${check.notes}'),
        ]),
      ),
    );
  }
}
