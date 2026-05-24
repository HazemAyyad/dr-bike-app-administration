import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/widgets/person_avatar_image.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import '../ledger/ledger_colors.dart';
import '../ledger/ledger_currency_tab_bar.dart';
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
              SliverToBoxAdapter(
                child: Obx(
                  () => LedgerCurrencyTabBar(
                    selected: controller.selectedCurrency.value,
                    onSelected: controller.changeCurrency,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              SliverToBoxAdapter(child: _SummaryCard(controller: controller)),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              SliverToBoxAdapter(
                child: Obx(
                  () => AppTabs(
                    tabs: controller.tabLabels,
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                    translateLabels: false,
                  ),
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
      final currency = controller.selectedCurrency.value;
      final totals = summary?.totalsFor(currency, customers: tab == 0);
      final taken = totals?.receivable ?? 0;
      final given = totals?.payable ?? 0;

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
                currency: currency,
                color: LedgerColors.takenGreen,
              ),
            ),
            Container(width: 1, height: 40.h, color: Colors.grey.shade300),
            Expanded(
              child: _SummaryItem(
                label: 'gave'.tr,
                amount: given,
                currency: currency,
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
  final String currency;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
        SizedBox(height: 4.h),
        Text(
          LedgerFormat.money(amount, currency: currency, fractionDigits: 1),
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
        SizedBox(width: 4.w),
        IconButton(
          tooltip: 'ledgerAddDebt'.tr,
          onPressed: controller.openPickPersonForDebt,
          icon: Icon(
            Icons.person_add_alt_1,
            color: LedgerColors.primaryBlue,
            size: 26.sp,
          ),
        ),
        IconButton(
          tooltip: 'addNewCustomer'.tr,
          onPressed: controller.openAddPersonFromLedger,
          icon: Icon(
            Icons.add_circle_outline,
            color: LedgerColors.primaryBlue,
            size: 26.sp,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final last = person.lastTransaction;
    final currency = controller.selectedCurrency.value;
    final balance = person.balance;
    final balanceColor = controller.balanceColor(balance);
    final balanceLabel = controller.balanceTypeLabel(balance);
    final lastActivity = controller.formatLastTransactionTime(last);

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
            PersonAvatarImage(
              imageUrl: person.imageUrl,
              width: 48.w,
              height: 48.w,
              circular: true,
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
                  if (lastActivity.isNotEmpty)
                    Text(
                      lastActivity,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                    ),
                  if (balanceLabel.isNotEmpty)
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  LedgerFormat.money(
                    person.balance,
                    currency: currency,
                    fractionDigits: 1,
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
