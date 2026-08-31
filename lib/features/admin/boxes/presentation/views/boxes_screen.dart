import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/boxes_controller.dart';
import '../widgets/view_boxes.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import 'package:intl/intl.dart';

class BoxesScreen extends GetView<BoxesController> {
  const BoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'boxes',
        employeeNameController: controller.boxNameController,
        label: 'boxName',
        onPressedFilter: () => controller.filterLists(),
        action: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'بحث في الصناديق',
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'فلترة الصناديق',
            onPressed: () => _showBoxesFilter(context, controller),
            icon: Obx(
              () => Badge(
                isLabelVisible: controller.listCurrencyFilter.value.isNotEmpty,
                smallSize: 7,
                child: Icon(
                  Icons.tune_rounded,
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'الصناديق اليومية',
            onPressed: () => Get.toNamed(AppRoutes.DAILYBOXESSCREEN),
            icon: Icon(
              Icons.today_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: GetBuilder<BoxesController>(
                builder: (controller) => _BoxesOverview(controller: controller),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            SliverToBoxAdapter(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            GetBuilder<BoxesController>(
              id: 'boxesSearch',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          child: SearchBar(
                            controller: controller.boxNameController,
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            textStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 16),
                            ),
                            hintStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 16),
                            ),
                            leading: const Icon(
                              Icons.search,
                            ),
                            trailing: [
                              IconButton(
                                tooltip: 'cancel'.tr,
                                onPressed: controller.closeSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                            hintText:
                                'ابحث بالاسم أو العملة أو الرصيد أو الحركة',
                            backgroundColor: WidgetStateProperty.all(
                              ThemeService.isDark.value
                                  ? AppColors.customGreyColor
                                  : AppColors.customGreyColor7,
                            ),
                            onChanged: (value) => controller.searchBar(value),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            const VeiwBoxes(),
          ],
        ),
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.CREATEBOXESSCREEN);
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

void _showBoxesFilter(BuildContext context, BoxesController controller) {
  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'فلترة الصناديق',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    controller.clearListFilters();
                    Get.back();
                  },
                  child: const Text('مسح الفلتر'),
                ),
              ],
            ),
            const Text('العملة'),
            SizedBox(height: 6.h),
            Obx(
              () => Wrap(
                spacing: 7.w,
                runSpacing: 6.h,
                children: [
                  ChoiceChip(
                    label: const Text('كل العملات'),
                    selected: controller.listCurrencyFilter.value.isEmpty,
                    onSelected: (_) => controller.listCurrencyFilter.value = '',
                  ),
                  ...controller.availableBoxCurrencies.map(
                    (currency) => ChoiceChip(
                      label: Text(currency),
                      selected: controller.listCurrencyFilter.value == currency,
                      onSelected: (_) =>
                          controller.listCurrencyFilter.value = currency,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  controller.applyListFilters();
                  Get.back();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('عرض النتائج'),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}

class _BoxesOverview extends StatelessWidget {
  const _BoxesOverview({required this.controller});

  final BoxesController controller;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final box in controller.filteredShownBoxes) {
      totals.update(
        box.currency,
        (value) => value + box.totalBalance,
        ifAbsent: () => box.totalBalance,
      );
    }
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: .78),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'ملخص الصناديق',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${controller.filteredShownBoxes.length} صندوق',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          if (totals.isEmpty)
            const Text('لا توجد صناديق ظاهرة',
                style: TextStyle(color: Colors.white70))
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: totals.entries
                  .map(
                    (entry) => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${NumberFormat('#,##0.00').format(entry.value)} ${entry.key}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
