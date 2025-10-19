import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../admin/admin_dashbord/presentation/widgets/actions_buttons.dart';
import '../controllers/employee_dashbord_controller.dart';
import '../widgets/employee_dashbord_tasks.dart';
import '../widgets/employee_floating_action_button.dart';
import '../widgets/employee_home_statistics_card.dart';

class EmployeeDashbordScreen extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          userName.isEmpty ? 'welcome'.tr : '${'welcome'.tr}  $userName',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            // بطاقات الإحصائيات
            const EmployeeHomeStatisticsCard(),
            SizedBox(height: 15.h),
            // أزرار الوظائف
            Obx(
              () {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                } else if (controller.employeeData.value == null) {
                  return const ShowNoData();
                }
                return Column(
                  children: [
                    Obx(
                      () {
                        if (controller.isTaskLoading.value) {
                          return Column(
                            children: [
                              SizedBox(height: 52.h),
                              const Center(child: CircularProgressIndicator()),
                            ],
                          );
                        }
                        if (controller.employeeData.value != null) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'tasks'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor5
                                              : AppColors.secondaryColor,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              if (controller.employeeData.value!.tasks
                                  .where((e) => e.status == 'ongoing')
                                  .isEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'لا يوجد مهمات'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeService.isDark.value
                                                ? AppColors.customGreyColor7
                                                : AppColors.customGreyColor4,
                                          ),
                                    ),
                                  ],
                                ),
                              ...controller.employeeData.value!.tasks
                                  .where((e) => e.status == 'ongoing')
                                  .where((e) =>
                                      e.startTime.day == DateTime.now().day)
                                  .take(5)
                                  .map((e) => EmployeeDashbordTasks(task: e)),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    controller.employeeData.value!.permissions.isNotEmpty
                        ? BuildActionButtons(
                            buttons: controller.buttons,
                            employeePermissions: controller
                                .employeeData.value?.permissions
                                .map((e) => e.id)
                                .toList(),
                          )
                        : const SizedBox.shrink(),
                  ],
                );
              },
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      floatingActionButton: const EmployeeFloatingActionButton(),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
