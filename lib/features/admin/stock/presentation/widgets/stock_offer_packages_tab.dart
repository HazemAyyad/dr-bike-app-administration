import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/offer_packages_controller.dart';
import 'offer_package_list_tile.dart';

/// Offer packages embedded as a stock screen tab.
class StockOfferPackagesTab extends GetView<OfferPackagesController> {
  const StockOfferPackagesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
            SizedBox(height: 8.h),
            if (controller.isLoading.value)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                ),
              )
            else if (controller.packages.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: const ShowNoData(),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.packages.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final pkg = controller.packages[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor4
                          : AppColors.whiteColor2,
                      borderRadius: BorderRadius.circular(8.r),
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
                  );
                },
              ),
            SizedBox(height: 64.h),
          ],
        ),
      );
    });
  }
}
