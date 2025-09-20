import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../projects/presentation/widgets/product_details_widgets/sup_text_and_dis.dart';
import '../controllers/target_section_controller.dart';

class GoalsDetailsScreen extends GetView<TargetSectionController> {
  const GoalsDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'targetDetails',
        action: false,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: IconButton(
              onPressed: () => controller.editGoal(),
              icon: const Icon(
                Icons.edit_calendar_outlined,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: GetBuilder<TargetSectionController>(
          builder: (controller) {
            if (controller.isAddLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 300.h),
                    const CircularProgressIndicator(),
                  ],
                ),
              );
            }
            if (controller.goalDetailsList == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 300.h),
                    const ShowNoData(),
                  ],
                ),
              );
            }
            return Column(
              children: [
                SizedBox(height: 20.h),
                // target details view
                if (controller.goalDetailsList!.name.isNotEmpty)
                  Row(
                    children: [
                      Flexible(
                        child: SupTextAndDis(
                          title: 'targetName',
                          discription: controller.goalDetailsList!.name,
                        ),
                      ),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${controller.goalDetailsList!.achievementPercentage}%',
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
                            Center(
                              child: SizedBox(
                                height: 55.h,
                                width: 60.w,
                                child: CircularProgressIndicator(
                                  value: (double.parse(controller
                                          .goalDetailsList!
                                          .achievementPercentage) /
                                      100),
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    double.parse(controller.goalDetailsList!
                                                .achievementPercentage) >=
                                            100
                                        ? Colors.green
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (controller.goalDetailsList!.type.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetType',
                    discription: controller.goalDetailsList!.type.tr,
                  ),
                if (controller.goalDetailsList!.form.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetTypeFormat',
                    discription: controller.goalDetailsList!.form.tr,
                  ),
                if (controller.goalDetailsList!.scope.isNotEmpty)
                  SupTextAndDis(
                    title: 'options',
                    discription: controller.goalDetailsList!.scope.tr,
                  ),

                if (controller.goalDetailsList!.targetedValue.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetValue',
                    discription: controller.goalDetailsList!.targetedValue,
                  ),
                if (controller.goalDetailsList!.currentValue.isNotEmpty)
                  SupTextAndDis(
                    title: 'currentValue',
                    discription: controller.goalDetailsList!.currentValue,
                  ),
                if (controller.goalDetailsList!.notes.isNotEmpty)
                  SupTextAndDis(
                    title: 'notes',
                    discription: controller.goalDetailsList!.notes,
                  ),
                SizedBox(height: 30.h),
              ],
            );
          },
        ),
      ),
    );
  }
}
