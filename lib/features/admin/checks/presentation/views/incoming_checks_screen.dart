import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/checks_controller.dart';
import '../widgets/checks_details.dart';
import '../widgets/custom_actions_appbar.dart';
import '../widgets/custom_list_veiw_builder.dart';

class IncomingChecksScreen extends StatelessWidget {
  const IncomingChecksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'incomingChecks'.tr,
        actions: const [CustomActionsAppBar(isNewCheck: false)],
      ),
      body: Stack(
        children: [
          GetBuilder<ChecksController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                  const SliverToBoxAdapter(
                    child: ChecksDetails(isOutGoing: false),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50.w),
                      child: SearchBar(
                        shadowColor:
                            WidgetStateProperty.all(Colors.transparent),
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
                  const CustomListVeiwBuilder(),
                  SliverToBoxAdapter(child: SizedBox(height: 50.h)),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          Get.toNamed(
            AppRoutes.NEWCHECKSCREEN,
            arguments: {'isNewCheck': false},
          );
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
