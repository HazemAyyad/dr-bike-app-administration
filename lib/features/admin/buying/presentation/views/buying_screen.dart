import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../binding/buying_binding.dart';
import '../controllers/bills_controller.dart';
import '../controllers/purchase_orders_controller.dart';
import '../controllers/return_purchases_controller.dart';
import '../widgets/bills_widgets/bills_list.dart';
import '../widgets/return_purchases_widgets/return_purchases_list.dart';

class BuyingScreen extends GetView<BillsController> {
  const BuyingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillsController>()) {
      BuyingBinding().dependencies();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'purchasesandReturns',
          action: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const TabBar(
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.primaryColor,
                  tabs: [
                    Tab(text: 'فواتير الشراء'),
                    Tab(text: 'استلام طلبات الشراء'),
                    Tab(text: 'مردودات المشتريات'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PurchaseInvoicesTab(),
                  const _PurchaseOrdersEntryTab(),
                  const _ReturnPurchasesEntryTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة'),
          onPressed: () => _showPurchaseCreateActions(context),
        ),
      ),
    );
  }

  void _showPurchaseCreateActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة عملية شراء',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                ),
                SizedBox(height: 10.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.add_shopping_cart_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: const Text('إنشاء فاتورة شراء جديدة'),
                  subtitle: const Text('اختيار مورد أو زبون ثم إضافة المنتجات'),
                  trailing: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primaryColor,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.isaddNewBill = '1';
                    Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseInvoicesTab extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.allBillsSearch.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => controller.getBills(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 80.h, 16.w, 24.h),
              children: const [ShowNoData()],
            ),
          );
        }
        final months =
            controller.allBillsSearch.keys.toList().reversed.toList();
        return RefreshIndicator(
          onRefresh: () async => controller.getBills(),
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 90.h),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final bills = controller.allBillsSearch[month] ?? [];
              return BillsList(month: month, bills: bills, page: '1');
            },
          ),
        );
      },
    );
  }
}

class _PurchaseOrdersEntryTab extends GetView<PurchaseOrdersController> {
  const _PurchaseOrdersEntryTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppTabs(
            tabs: controller.tabs,
            currentTab: controller.currentTab,
            changeTab: controller.changeTab,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        SliverToBoxAdapter(
          child: _BuyingSearchBar(
            onChanged: controller.searchBar,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        GetBuilder<PurchaseOrdersController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final current = controller.currentTab.value;
            final source = current == 0
                ? controller.unprocessedSearch
                : current == 1
                    ? controller.notMatchedSearch
                    : current == 2
                        ? controller.completedSearch
                        : controller.depositsSearch;

            if (source.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: ShowNoData()),
              );
            }

            final months = source.keys.toList().reversed.toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, section) {
                  final month = months[section];
                  final bills = source[month]!.reversed.toList();
                  return BillsList(
                    month: month,
                    bills: bills,
                    page: current == 0
                        ? '2'
                        : current == 2
                            ? '1'
                            : current == 1
                                ? '3'
                                : '4',
                  );
                },
                childCount: months.length,
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: 90.h)),
      ],
    );
  }
}

class _ReturnPurchasesEntryTab extends GetView<ReturnPurchasesController> {
  const _ReturnPurchasesEntryTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            SliverToBoxAdapter(
              child: _BuyingSearchBar(
                onChanged: controller.searchBar,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            GetBuilder<ReturnPurchasesController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final source = controller.currentTab.value == 0
                    ? controller.returnPurchasesSearch
                    : controller.deliveredPurchasesSearch;

                if (source.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: ShowNoData()),
                  );
                }

                final months = source.keys.toList().reversed.toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, section) {
                      final month = months[section];
                      final bills = source[month]!.reversed.toList();
                      return ReturnPurchasesList(month: month, bills: bills);
                    },
                    childCount: months.length,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 90.h)),
          ],
        ),
        PositionedDirectional(
          start: 18.w,
          bottom: 18.h,
          child: SizedBox(
            height: 55.h,
            width: 55.w,
            child: FloatingActionButton(
              heroTag: 'buying_returns_fab',
              onPressed: () {
                Get.toNamed(AppRoutes.CREATEPURCHASERETURNSCREEN);
              },
              backgroundColor: AppColors.secondaryColor,
              elevation: 2.0,
              shape: const CircleBorder(),
              child: Icon(
                Icons.add,
                color: AppColors.whiteColor,
                size: 42.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuyingSearchBar extends StatelessWidget {
  const _BuyingSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: SearchBar(
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        leading: const Icon(Icons.search),
        hintText: 'search'.tr,
        backgroundColor: WidgetStateProperty.all(
          ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.customGreyColor7,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
