import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/offer_packages_controller.dart';
import '../widgets/offer_package_list_tile.dart';
import '../../../../../core/helpers/show_no_data.dart';

class OfferPackagesScreen extends GetView<OfferPackagesController> {
  const OfferPackagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'offerPackages', action: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.prepareCreate();
          Get.toNamed(AppRoutes.ADDEDITOFFERPACKAGESCREEN);
        },
        backgroundColor: ThemeService.isDark.value
            ? AppColors.primaryColor
            : AppColors.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 600.h,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                );
              }
              if (controller.packages.isEmpty) {
                return const SliverFillRemaining(child: ShowNoData());
              }
              return SliverList.builder(
                itemCount: controller.packages.length,
                itemBuilder: (context, index) {
                  final pkg = controller.packages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
                    child: Column(
                      children: [
                        SizedBox(height: index == 0 ? 10.h : 0),
                        Container(
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor4
                                : AppColors.whiteColor2,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: OfferPackageListTile(
                            pkg: pkg,
                            showStockWarning: controller.currentTab.value == 1,
                            onTap: () {
                              controller.prepareEdit(pkg);
                              Get.toNamed(AppRoutes.ADDEDITOFFERPACKAGESCREEN);
                            },
                            onEdit: () {
                              controller.prepareEdit(pkg);
                              Get.toNamed(AppRoutes.ADDEDITOFFERPACKAGESCREEN);
                            },
                            onDelete: () => controller.deletePackage(pkg),
                          ),
                        ),
                        SizedBox(
                          height: index == controller.packages.length - 1
                              ? 80.h
                              : 0,
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
