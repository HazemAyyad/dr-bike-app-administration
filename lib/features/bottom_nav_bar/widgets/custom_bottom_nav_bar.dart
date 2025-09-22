import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/initial_bindings.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/assets_manger.dart';
import '../../admin/counters/data/repositories/countrers_implement.dart';
import '../../admin/counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../admin/counters/domain/usecases/get_report_information_usecase.dart';
import '../../admin/counters/presentation/controllers/counters_controller.dart';
import '../controllers/bottom_nav_bar_controller.dart';
import 'build_nav_item.dart';

class CustomBottomNavigationBar extends GetView<BottomNavBarController> {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 70.h, // ارتفاع شريط التنقل
        child: Obx(
          () => Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.greyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
              ),
            ),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BuildNavItem(
                    assetImage: AssetsManager.homeIcon,
                    isSelected: controller.currentIndex.value == 0,
                    label: 'home'.tr,
                    onTap: () => controller.changePage(0),
                  ),
                  userType == 'admin'
                      ? BuildNavItem(
                          assetImage: AssetsManager.taskIcon,
                          isSelected: controller.currentIndex.value == 1,
                          label: 'statistics'.tr,
                          onTap: () {
                            CountersController(
                              getReportInformationUsecase:
                                  GetReportInformationUsecase(
                                countersRepository:
                                    Get.find<CountrersImplement>(),
                              ),
                              getReportByType: GetReportByTypeUsecase(
                                countersRepository:
                                    Get.find<CountrersImplement>(),
                              ),
                            ).getReportInformation();
                            controller.changePage(1);
                          },
                        )
                      : BuildNavItem(
                          assetImage: AssetsManager.taskIcon,
                          isSelected: controller.currentIndex.value == 1,
                          label: 'tasks'.tr,
                          onTap: () => controller.changePage(1),
                        ),
                  BuildNavItem(
                    assetImage: AssetsManager.profileIcon,
                    isSelected: controller.currentIndex.value == 2,
                    label: 'profile'.tr,
                    onTap: () => controller.changePage(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
