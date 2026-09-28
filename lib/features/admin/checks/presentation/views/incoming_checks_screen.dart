import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/checks_controller.dart';
import '../widgets/checks_data_details.dart';
import '../widgets/custom_actions_appbar.dart';
import '../widgets/custom_list_veiw_builder.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class IncomingChecksScreen extends GetView<ChecksController> {
  const IncomingChecksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => CustomAppBar(
            title: 'incomingChecks'.tr,
            titleWidget: controller.isChecksSearchOpen.value
                ? TextField(
                    controller: controller.checksSearchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: controller.searchBar,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'search'.tr,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : null,
            actions: const [CustomActionsAppBar(isNewCheck: false)],
          ),
        ),
      ),
      body: Stack(
        children: [
          Obx(
            () {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return AppPullToRefresh(
                onRefresh: controller.pullToRefresh,
                child: CustomScrollView(
                  physics: kRefreshableScrollPhysics,
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                    const SliverToBoxAdapter(
                      child: ChecksDataDetails(isOutGoing: false),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                    SliverToBoxAdapter(
                      child: Obx(
                        () => AppTabs(
                          tabs: [
                            '${'didNotActOnIt'.tr} (${controller.notActedTabCount.value})',
                            '${'actedOnIt'.tr} (${controller.actedTabCount.value})',
                            '${'archive'.tr} (${controller.archiveTabCount.value})',
                          ],
                          currentTab: controller.currentTab,
                          changeTab: controller.changeTab,
                          translateLabels: false,
                          height: 38.h,
                          horizontalPadding: 6.w,
                          tabHorizontalPadding: 10.w,
                          tabVerticalPadding: 7.h,
                          tabHorizontalMargin: 2.w,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                    const CustomListVeiwBuilder(),
                    SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: canCreateIncomingChecks
          ? AddFloatingActionButton(
              onPressed: () {
                controller.isEdit.value = false;
                controller.getCeckData(isOutgoing: false);
              },
            )
          : null,
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
