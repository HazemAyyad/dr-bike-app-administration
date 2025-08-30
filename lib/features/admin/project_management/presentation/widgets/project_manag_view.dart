import 'package:doctorbike/features/admin/project_management/presentation/controllers/project_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class ProjectManagementView extends GetView<ProjectManagementController> {
  const ProjectManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.22,
            ),
            key: ValueKey<int>(controller.currentTab.value),
            itemCount: controller.projectList.length,
            itemBuilder: (context, index) {
              final order = controller.projectList[index];
              return InkWell(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                onTap: () => Get.toNamed(
                  AppRoutes.PROJECTDETAILSSCREEN,
                  arguments: order,
                ),
                child: Container(
                  padding: EdgeInsets.all(15),
                  // margin: EdgeInsets.symmetric(vertical: 5.h,),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Column(
                    children: [
                      Flexible(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 40.h,
                              width: 40.w,
                              child: CircularProgressIndicator(
                                value: (50 / 100),
                                strokeWidth: 5.w,
                                backgroundColor: Colors.grey[500],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              '${15}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.whiteColor2
                                        : AppColors.blackColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        order['projectName'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: ThemeService.isDark.value
                                  ? AppColors.whiteColor2
                                  : AppColors.blackColor,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
