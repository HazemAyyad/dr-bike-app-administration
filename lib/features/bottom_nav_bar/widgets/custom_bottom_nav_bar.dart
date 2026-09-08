import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/initial_bindings.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';
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
        height: 62.h,
        child: Obx(
          () => Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? const Color(0xFF20202D)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
              ),
              border: Border(
                top: BorderSide(
                  color: ThemeService.isDark.value
                      ? const Color(0xFF4A465F)
                      : AppColors.operationalPurple.withValues(alpha: .10),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: ThemeService.isDark.value ? .28 : .07,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Obx(() {
              final role = sessionUserType.value.isNotEmpty
                  ? sessionUserType.value
                  : userType;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BuildNavItem(
                    icon: Icons.home_outlined,
                    isSelected: controller.currentIndex.value == 0,
                    label: 'home'.tr,
                    onTap: () => _selectPage(0),
                  ),
                  role == 'admin'
                      ? BuildNavItem(
                          icon: Icons.bar_chart_rounded,
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
                          icon: Icons.task_alt_rounded,
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
                      icon: Icons.groups_2_outlined,
                      isSelected: controller.currentIndex.value == 2,
                      label: 'employeeDepartment'.tr,
                      onTap: () => _selectPage(2),
                    ),
                  if (role != 'admin')
                    BuildNavItem(
                      icon: Icons.insights_rounded,
                      isSelected: controller.currentIndex.value == 2,
                      label: 'أدائي',
                      onTap: () => _selectPage(2),
                    ),
                  BuildNavItem(
                    icon: Icons.person_outline_rounded,
                    isSelected: controller.currentIndex.value == 3,
                    label: 'profile'.tr,
                    onTap: () => _selectPage(3),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
