import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/checks_controller.dart';
import '../widgets/checks_details.dart';
import '../widgets/custom_actions_appbar.dart';
import '../widgets/custom_list_veiw_builder.dart';

class OutgoingChecksScreen extends GetView<ChecksController> {
  const OutgoingChecksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'outgoingChecks'.tr,
        actions: const [CustomActionsAppBar(isNewCheck: true)],
      ),
      body: Stack(
        children: [
          Obx(
            () {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                  const SliverToBoxAdapter(
                    child: ChecksDetails(isOutGoing: true),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(
                    child: AppTabs(
                      tabs: controller.tabs,
                      currentTab: controller.currentTab,
                      changeTab: controller.changeTab,
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                  const CustomListVeiwBuilder(),
                  SliverToBoxAdapter(child: SizedBox(height: 50.h)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
