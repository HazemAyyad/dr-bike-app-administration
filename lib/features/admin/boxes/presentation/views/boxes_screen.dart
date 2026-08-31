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
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SearchBar(
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 16),
                  ),
                  hintStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 16),
                  ),
                  leading: const Icon(
                    Icons.search,
                  ),
                  hintText: 'search'.tr,
                  backgroundColor: WidgetStateProperty.all(
                    ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor7,
                  ),
                  onChanged: (value) => controller.searchBar(value),
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
      margin: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 2.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: .78),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
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
          SizedBox(height: 12.h),
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
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
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
