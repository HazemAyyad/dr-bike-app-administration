import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../create_tasks/presentation/widgets/task_form_section_card.dart';
import '../../../projects/presentation/widgets/product_details_widgets/sup_text_and_dis.dart';
import '../controllers/target_section_controller.dart';

class GoalsDetailsScreen extends GetView<TargetSectionController> {
  const GoalsDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                    const CircularProgressIndicator(),
                  ],
                ),
              );
            }
            final goal = controller.goalDetailsList!.goal;
            final achievement =
                double.tryParse(goal.achievementPercentage) ?? 0;
            final progress = (achievement / 100).clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TaskFormSectionCard(
                  compact: true,
                  title: 'targetDetails',
                  child: Column(
                    children: [
                      if (goal.name.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: SupTextAndDis(
                                title: 'targetName',
                                discription: goal.name,
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${achievement.toStringAsFixed(0)}%',
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
                                SizedBox(
                                  height: 58.h,
                                  width: 58.h,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      achievement >= 100
                                          ? Colors.green
                                          : AppColors.operationalPurple,
                                    ),
                                  ),
                                ),
                              ],
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
                      if (goal.calculationMode.isNotEmpty)
                        SupTextAndDis(
                          title: 'calculationMode',
                          discription: goal.calculationMode.tr,
                        ),
                      if (goal.form.isNotEmpty)
                        SupTextAndDis(
                          title: 'options',
                          discription: goal.form.tr,
                        ),
                    ],
                  ),
                ),
                TaskFormSectionCard(
                  compact: true,
                  title: 'followUp',
                  child: Column(
                    children: [
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
                      if (goal.storeSections.isNotEmpty)
                        ...goal.storeSections.map(
                          (e) => SupTextAndDis(
                            title: 'store_sections',
                            discription: e.name,
                          ),
                        ),
                      if (goal.products != null && goal.products!.isNotEmpty)
                        ...List.generate(
                          goal.products!.length,
                          (index) => SupTextAndDis(
                            showLine: false,
                            title: '${'productName'.tr} ${index + 1}',
                            discription: goal.products![index].name,
                          ),
                        ),
                    ],
                  ),
                ),
                TaskFormSectionCard(
                  compact: true,
                  title: 'targetValue',
                  child: Column(
                    children: [
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
                      if (goal.startDate.isNotEmpty)
                        SupTextAndDis(
                          title: 'fromDate',
                          discription: showData(goal.startDate),
                        ),
                      if (goal.dueDate.isNotEmpty)
                        SupTextAndDis(
                          title: 'date',
                          discription: showData(goal.dueDate),
                        ),
                      if ((goal.notes ?? '').isNotEmpty)
                        SupTextAndDis(
                          title: 'notes',
                          discription: goal.notes!,
                        ),
                    ],
                  ),
                ),
                if (controller.goalDetailsList!.goalLogs.isNotEmpty)
                  TaskFormSectionCard(
                    compact: true,
                    title: 'log',
                    child: Column(
                      children: controller.goalDetailsList!.goalLogs
                          .map(
                            (e) => SupTextAndDis(
                              title: e.title,
                              discription: e.description,
                            ),
                          )
                          .toList(),
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
