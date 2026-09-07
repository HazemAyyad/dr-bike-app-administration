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
import '../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../controllers/bottom_nav_bar_controller.dart';
import 'build_nav_item.dart';

class CustomBottomNavigationBar extends GetView<BottomNavBarController> {
  const CustomBottomNavigationBar({Key? key, this.onNavigate})
      : super(key: key);

  final ValueChanged<int>? onNavigate;

  void _selectPage(int index) {
    final callback = onNavigate;
    callback != null ? callback(index) : controller.changePage(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BottomNavBarController>()) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: SizedBox(
        height: 66.h,
        child: Obx(
          () => Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.greyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.operationalPurple.withValues(alpha: .10),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.operationalNavy.withValues(alpha: .08),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Obx(
              () {
                final role = sessionUserType.value.isNotEmpty
                    ? sessionUserType.value
                    : userType;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    BuildNavItem(
                      assetImage: AssetsManager.homeIcon,
                      isSelected: controller.currentIndex.value == 0,
                      label: 'home'.tr,
                      onTap: () => _selectPage(0),
                    ),
                    role == 'admin'
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
                              _selectPage(1);
                            },
                          )
                        : BuildNavItem(
                            assetImage: AssetsManager.taskIcon,
                            isSelected: controller.currentIndex.value == 1,
                            label: 'tasks'.tr,
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Get.find<EmployeeDashbordController>()
                                    .scrollToToday();
                              });
                              _selectPage(1);
                            },
                          ),
                    if (role == 'admin')
                      BuildNavItem(
                        assetImage: AssetsManager.usersIcon,
                        isSelected: controller.currentIndex.value == 2,
                        label: 'employeeDepartment'.tr,
                        onTap: () => _selectPage(2),
                      ),
                    BuildNavItem(
                      assetImage: AssetsManager.profileIcon,
                      isSelected: controller.currentIndex.value ==
                          (role == 'admin' ? 3 : 2),
                      label: 'profile'.tr,
                      onTap: () => _selectPage(
                        role == 'admin' ? 3 : 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
