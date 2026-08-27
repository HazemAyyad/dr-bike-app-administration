// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
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
              Row(
                children: [
                  Expanded(
                    child: _UpcomingChecksCard(
                      title: 'أقرب 5 شيكات واردة',
                      icon: Icons.call_received_rounded,
                      color: Colors.green,
                      checks: controller
                              .mainDashboardDataModel?.upcomingIncomingChecks ??
                          const [],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _UpcomingChecksCard(
                      title: 'أقرب 5 شيكات صادرة',
                      icon: Icons.call_made_rounded,
                      color: Colors.orange,
                      checks: controller
                              .mainDashboardDataModel?.upcomingOutgoingChecks ??
                          const [],
                    ),
                  ),
                ],
              ),
              // الصف الأول: ديون لنا وديون علينا
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'debtsForUs',
                      imageicon: AssetsManager.cashIcon,
                      value: controller
                              .mainDashboardDataModel?.totalDebtsOwedToUs ??
                          '0',
                      subtitle: 'currency',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: StatCard(
                      title: 'debtsOnUs',
                      imageicon: AssetsManager.cashIcon,
                      value:
                          controller.mainDashboardDataModel?.totalDebtsWeOwe ??
                              '0',
                      subtitle: 'currency',
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
                      imageicon: AssetsManager.productIcon,
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
                          imageicon: AssetsManager.usersIcon,
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
                      imageicon: AssetsManager.doneIcon,
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
                      imageicon: AssetsManager.cancelIcon,
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
                imageicon: AssetsManager.moneyIcon,
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
            .join('\n');

    return Material(
      color:
          ThemeService.isDark.value ? AppColors.customGreyColor4 : Colors.white,
      borderRadius: BorderRadius.circular(5.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(5.r),
        onTap: checks.isEmpty ? null : () => _showDetails(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(height: 5.h),
              Text(title,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 6.h),
              Text(summary,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700)),
              if (checks.isNotEmpty)
                Text('اضغط لعرض التفاصيل',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey)),
            ],
          ),
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
