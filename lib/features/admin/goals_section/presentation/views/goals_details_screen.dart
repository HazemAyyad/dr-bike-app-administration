import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
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
            final goal = controller.goalDetailsList!.goal;
            if (controller.goalDetailsList == null) {
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // target details view
                if (goal.name.isNotEmpty)
                  Row(
                    children: [
                      Flexible(
                        child: SupTextAndDis(
                          title: 'targetName',
                          discription: goal.name,
                        ),
                      ),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${goal.achievementPercentage}%',
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
                                          .goal
                                          .achievementPercentage) /
                                      100),
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    double.parse(controller.goalDetailsList!
                                                .goal.achievementPercentage) >=
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
                if (goal.scope.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetType',
                    discription: goal.scope.tr,
                  ),
                if (goal.type.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetTypeFormat',
                    discription: goal.type.tr,
                  ),
                if (goal.form.isNotEmpty)
                  SupTextAndDis(
                    title: 'options',
                    discription: goal.form.tr,
                  ),
                if (goal.employee != null)
                  SupTextAndDis(
                    title: 'employeeName',
                    discription: goal.employee!.name,
                  ),
                if (goal.people?.isNotEmpty ?? false) ...[
                  if (goal.people!.first.customerName.isNotEmpty)
                    SupTextAndDis(
                      title: 'customerName',
                      discription: goal.people!.first.customerName,
                    ),
                  if (goal.people!.first.sellerName.isNotEmpty)
                    SupTextAndDis(
                      title: 'sellerName',
                      discription: goal.people!.first.sellerName,
                    ),
                ],
                if (goal.box != null && goal.box!.name.isNotEmpty)
                  SupTextAndDis(
                    title: 'boxName',
                    discription: goal.box!.name,
                  ),
                if (goal.products != null && goal.products!.isNotEmpty)
                  ...List.generate(
                    goal.products!.length,
                    (index) => SupTextAndDis(
                      showLine: false,
                      title: '${'productName'.tr}${index + 1} ',
                      discription: goal.products![index].name,
                    ),
                  ),
                if (goal.mainCategories != null &&
                    goal.mainCategories!.isNotEmpty)
                  ...goal.mainCategories!.map(
                    (e) => SupTextAndDis(
                      title: 'main_categories',
                      discription: e.name,
                    ),
                  ),
                if (goal.subCategories != null &&
                    goal.subCategories!.isNotEmpty)
                  ...goal.subCategories!.map(
                    (e) => SupTextAndDis(
                      title: 'sub_categories',
                      discription: e.name,
                    ),
                  ),

                if (goal.targetedValue.isNotEmpty)
                  SupTextAndDis(
                    title: 'targetValue',
                    discription: goal.targetedValue,
                  ),
                if (goal.currentValue.isNotEmpty)
                  SupTextAndDis(
                    title: 'currentValue',
                    discription: goal.currentValue,
                  ),
                if (goal.dueDate.isNotEmpty)
                  SupTextAndDis(
                    title: 'date',
                    discription: showData(goal.dueDate),
                  ),
                if (goal.notes!.isNotEmpty)
                  SupTextAndDis(
                    title: 'notes',
                    discription: goal.notes!,
                  ),
                Row(
                  children: [
                    Text(
                      'log'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                    ),
                  ],
                ),
                ...controller.goalDetailsList!.goalLogs.map(
                  (e) => SupTextAndDis(
                    title: e.title,
                    discription: e.description,
                  ),
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
