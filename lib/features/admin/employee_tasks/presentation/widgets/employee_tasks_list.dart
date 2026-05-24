import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
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
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        );
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
