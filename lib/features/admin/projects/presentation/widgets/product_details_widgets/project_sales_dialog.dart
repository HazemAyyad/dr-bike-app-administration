import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/project_sale_model.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/project_service.dart';

class ProjectSalesDialog extends GetView<ProjectController> {
  const ProjectSalesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'projectSales'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              color: AppColors.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'productName'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.whiteColor,
                        ),
                  ),
                  Text(
                    'price'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.whiteColor,
                        ),
                  ),
                ],
              ),
            ),
            Obx(
              () {
                if (controller.isLoading.value) {
                  return SizedBox(
                      height: 300.h,
                      child: const Center(child: CircularProgressIndicator()));
                }
                if (ProjectService().projectSales.value == null ||
                    ProjectService().projectSales.value!.projectSales.isEmpty) {
                  return SizedBox(height: 300.h, child: const ShowNoData());
                }
                return SizedBox(
                  height: 300.h,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              ProjectSale project = ProjectService()
                                  .projectSales
                                  .value!
                                  .projectSales
                                  .toList()
                                  .reversed
                                  .toList()[index];
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                margin: EdgeInsets.symmetric(vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: ThemeService.isDark.value
                                      ? AppColors.customGreyColor
                                      : AppColors.whiteColor2,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        project.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeService.isDark.value
                                                  ? AppColors.whiteColor2
                                                  : AppColors.blackColor,
                                            ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        '${project.productCost} ${'currency'.tr}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeService.isDark.value
                                                  ? AppColors.whiteColor2
                                                  : AppColors.blackColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: ProjectService()
                                .projectSales
                                .value!
                                .projectSales
                                .length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 15.h),
            GetBuilder<ProjectController>(
              builder: (controller) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        ProjectService().projectSales.value == null
                            ? '${'totalSalesValue'.tr} ${'0'} ${'currency'.tr}'
                            : '${'totalSalesValue'.tr} ${NumberFormat('#,###').format(ProjectService().projectSales.value!.totalCosts)} ${'currency'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: ThemeService.isDark.value
                                  ? AppColors.whiteColor2
                                  : AppColors.blackColor,
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
