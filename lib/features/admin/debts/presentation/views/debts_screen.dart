import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import '../ledger/ledger_colors.dart';
import '../ledger/ledger_format.dart';
import '../ledger/period_filter_sheet.dart';
class DebtsScreen extends GetView<DebtLedgerController> {
  const DebtsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerColors.background,
      extendBody: true,
      appBar: AppBar(
        title: Text('debtBook'.tr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: AppPullToRefresh(
          onRefresh: controller.pullToRefresh,
          child: CustomScrollView(
            physics: kRefreshableScrollPhysics,
            slivers: [
              SliverToBoxAdapter(child: _SummaryCard(controller: controller)),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              SliverToBoxAdapter(
                child: AppTabs(
                  tabs: controller.tabs,
                  currentTab: controller.currentTab,
                  changeTab: controller.changeTab,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              SliverToBoxAdapter(child: _SearchRow(controller: controller)),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              Obx(() {
                final loading = controller.isLoading.value;
                final _ = controller.people.length;
                final __ = controller.searchQuery.value;
                if (loading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = controller.filteredPeople;
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('ledgerNoTransactions'.tr)),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PersonRow(
                      person: list[index],
                      controller: controller,
                    ),
                    childCount: list.length,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DebtLedgerController controller;

  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.currentTab.value;
      final summary = controller.summary.value;
      final taken = tab == 0
          ? (summary?.totalTakenCustomers ?? 0)
          : (summary?.totalTakenSellers ?? 0);
      final given = tab == 0
          ? (summary?.totalGivenCustomers ?? 0)
          : (summary?.totalGivenSellers ?? 0);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: LedgerColors.cardBlue,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'took'.tr,
                amount: taken,
                color: LedgerColors.takenGreen,
              ),
            ),
            Container(width: 1, height: 40.h, color: Colors.grey.shade300),
            Expanded(
              child: _SummaryItem(
                label: 'gave'.tr,
                amount: given,
                color: LedgerColors.givenRed,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
        SizedBox(height: 4.h),
        Text(
          LedgerFormat.shekel2(amount),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  final DebtLedgerController controller;

  const _SearchRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchBar(
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            leading: const Icon(Icons.search),
            hintText: 'search'.tr,
            backgroundColor: WidgetStateProperty.all(
              ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
            ),
            onChanged: controller.onSearchChanged,
          ),
        ),
        SizedBox(width: 8.w),
        IconButton(
          onPressed: () => Get.bottomSheet(
            const PeriodFilterSheet(),
            isScrollControlled: true,
          ),
          icon: const Icon(Icons.filter_list, color: LedgerColors.primaryBlue),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final LedgerPerson person;
  final DebtLedgerController controller;

  const _PersonRow({required this.person, required this.controller});

  String get _initial =>
      person.name.isNotEmpty ? person.name.substring(0, 1) : '?';

  @override
  Widget build(BuildContext context) {
    final last = person.lastTransaction;
    final balanceColor = controller.balanceColor(person.balance);
    final label = last?.typeLabel ?? '';
    final date = last?.createdAt ?? last?.transactionDate ?? '';

    return InkWell(
      onTap: () => controller.openPerson(person),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: LedgerColors.cardBlue,
              child: Text(
                _initial,
                style: TextStyle(
                  color: LedgerColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: last?.type == 'taken'
                            ? LedgerColors.takenGreen
                            : LedgerColors.givenRed,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              LedgerFormat.shekel2(person.balance),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
