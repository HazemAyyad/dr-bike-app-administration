import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../controllers/employee_tasks_controller.dart';
import 'employee_tasks_lists.dart';

class EmployeeTasks extends GetView<EmployeeTasksController> {
  const EmployeeTasks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Obx(() {
      final rows = controller.flatTaskRows;
      final listKey = controller.listUiKey;
      controller.listEpoch.value;
      controller.tasksViewMode.value;
      controller.currentTab.value;

      if (controller.isLoading.value) {
        return const _EmployeeTasksSkeletonSliver();
      }

      if (rows.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: ShowNoData(),
        );
      }

      return SliverList.builder(
        key: ValueKey(listKey),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.isHeader) {
            return _DayHeader(
              dayKey: row.dayKey!,
              isFirst: row.isFirstHeader,
              theme: theme,
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: EmployeeTasksLists(
              key: ValueKey('task_${row.task!.taskId}'),
              controller: controller,
              order: row.task!,
              index: index,
            ),
          );
        },
      );
    });
  }
}

class _EmployeeTasksSkeletonSliver extends StatelessWidget {
  const _EmployeeTasksSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.operationalCardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonCircle(size: 32.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: index.isEven ? 0.72 : 0.58,
                            child: SkeletonBlock(
                              width: double.infinity,
                              height: 13.h,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          FractionallySizedBox(
                            widthFactor: index.isEven ? 0.52 : 0.68,
                            child: SkeletonBlock(
                              width: double.infinity,
                              height: 10.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SkeletonBlock(width: 54.w, height: 18.h, radius: 6),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SkeletonBlock(width: 68.w, height: 18.h, radius: 6),
                    SizedBox(width: 6.w),
                    SkeletonBlock(width: 48.w, height: 18.h, radius: 6),
                    const Spacer(),
                    SkeletonBlock(width: 38.w, height: 10.h, radius: 5),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.dayKey,
    required this.isFirst,
    required this.theme,
  });

  final String dayKey;
  final bool isFirst;
  final TextStyle theme;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dayKey);
    final todayKey = EmployeeTasksController.dateKeyFrom(DateTime.now());
    final isToday = dayKey == todayKey;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, isFirst ? 4.h : 8.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, d/M/yyyy', Get.locale?.languageCode)
                      .format(date),
                  style: theme.copyWith(
                    color: isToday
                        ? AppColors.operationalPurple
                        : AppColors.operationalNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    height: 1.2,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.operationalPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'today'.tr,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.operationalPurple,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            height: 1,
            color: AppColors.operationalPurple.withValues(alpha: 0.35),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
