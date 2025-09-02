import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../admin/--/presentation/admin_dashbord/widgets/actions_buttons.dart';
import '../../../../admin/--/presentation/admin_dashbord/widgets/search_bar.dart';
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
          '${'welcomeBack.'.tr} Mohamed',
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
            CustomSearchBar(),
            SizedBox(height: 20.h),
            // بطاقات الإحصائيات
            EmployeeHomeStatisticsCard(),
            SizedBox(height: 15.h),
            // أزرار الوظائف
            Obx(
              () {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                } else if (controller.employeeData.value == null) {
                  return ShowNoData();
                }
                return Column(
                  children: [
                    Obx(
                      () {
                        if (controller.isTaskLoading.value) {
                          return Column(
                            children: [
                              SizedBox(height: 52.h),
                              Center(child: CircularProgressIndicator()),
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
                                              ? AppColors.customGreyColor
                                              : AppColors.secondaryColor,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              if (controller.employeeData.value!.tasks.isEmpty)
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
                                            color: AppColors.customGreyColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ...controller.employeeData.value!.tasks
                                  .take(5)
                                  .map(
                                    (e) => EmployeeDashbordTasks(e: e),
                                  ),
                            ],
                          );
                        }
                        return SizedBox.shrink();
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
                        : SizedBox.shrink(),
                  ],
                );
              },
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      floatingActionButton: EmployeeFloatingActionButton(),
    );
  }
}
