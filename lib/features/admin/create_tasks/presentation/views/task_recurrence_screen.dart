import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

/// Dedicated recurrence configuration screen (v2 lazy recurrence).
class TaskRecurrenceScreen extends GetView<CreateTaskController> {
  const TaskRecurrenceScreen({Key? key}) : super(key: key);

  static const weekdays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(title: 'recurrenceSettings'.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.operationalPurple,
              minimumSize: Size(double.infinity, 52.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('save'.tr),
          ),
        ),
      ),
      body: Obx(
        () => ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _SectionCard(
              title: 'repeatPattern'.tr,
              child: Wrap(
                spacing: 8.w,
                children: ['noRepeat', 'daily', 'weekly', 'monthly', 'yearly']
                    .map(
                      (t) => ChoiceChip(
                        label: Text(t.tr),
                        selected: controller.selectedDays.value == t,
                        selectedColor:
                            AppColors.operationalPurple.withValues(alpha: 0.2),
                        onSelected: (_) {
                          controller.selectedDays.value = t;
                          controller.isRecurrenceVisible.value = t != 'noRepeat';
                          controller.updateRecurrenceSummary();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            if (controller.selectedDays.value == 'weekly') ...[
              SizedBox(height: 16.h),
              _SectionCard(
                title: 'selectWeekdays'.tr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weekdays.map((day) {
                    final selected =
                        controller.selectedDaysList.contains(day);
                    return GestureDetector(
                      onTap: () => controller.toggleDay(day),
                      child: CircleAvatar(
                        radius: 22.r,
                        backgroundColor: selected
                            ? AppColors.operationalPurple
                            : AppColors.whiteColor,
                        child: Text(
                          day.substring(0, 1).tr,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.operationalNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            SizedBox(height: 16.h),
            _SectionCard(
              title: 'duration'.tr,
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text('forever'.tr),
                    value: 'forever',
                    groupValue: controller.durationType.value,
                    activeColor: AppColors.operationalPurple,
                    onChanged: (v) => controller.durationType.value = v!,
                  ),
                  RadioListTile<String>(
                    title: Text('endAfterTimes'.tr),
                    value: 'end_after_count',
                    groupValue: controller.durationType.value,
                    activeColor: AppColors.operationalPurple,
                    onChanged: (v) => controller.durationType.value = v!,
                  ),
                  if (controller.durationType.value == 'end_after_count')
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'occurrenceCount'.tr,
                        filled: true,
                        fillColor: AppColors.whiteColor,
                      ),
                      onChanged: (v) =>
                          controller.endAfterCount.value = int.tryParse(v) ?? 0,
                    ),
                  RadioListTile<String>(
                    title: Text('endAtDate'.tr),
                    value: 'end_date',
                    groupValue: controller.durationType.value,
                    activeColor: AppColors.operationalPurple,
                    onChanged: (v) => controller.durationType.value = v!,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            _SectionCard(
              title: 'summary'.tr,
              child: Text(
                controller.recurrenceSummary.value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.operationalNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}
