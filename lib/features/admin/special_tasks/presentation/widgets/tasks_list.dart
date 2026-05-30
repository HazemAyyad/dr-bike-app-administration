import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_calendar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_tasks/presentation/widgets/task_status_badge.dart';
import '../controllers/special_tasks_controller.dart';

class TasksList extends GetView<SpecialTasksController> {
  const TasksList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return GetBuilder<SpecialTasksController>(
      id: 'specialTasksList',
      builder: (controller) {
        if (controller.isLoading.value) {
          return const _SpecialTasksSkeletonSliver();
        }

        final map = _currentMap(controller);
        final hasTasks = map.values.any((tasks) => tasks.isNotEmpty);
        if (map.isEmpty || !hasTasks) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ShowNoData(),
          );
        }

        final keys = controller.currentTab.value == 1
            ? map.keys.toList()
            : controller.orderedDisplayKeys(map.keys.toList());

        return SliverList.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final date = keys[index];
            final tasksForDate = List<SpecialTaskModel>.from(map[date] ?? [])
              ..sort((a, b) => a.startDate.compareTo(b.startDate));
            if (tasksForDate.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                children: [
                  if (controller.currentTab.value != 1)
                    _DayHeader(
                      date: date,
                      isFirst: index == 0,
                      theme: theme,
                    ),
                  ...tasksForDate.map(
                    (task) {
                      final key = task.id.toString();
                      controller.checkedMap.putIfAbsent(key, () => false.obs);
                      return _SpecialTaskCard(
                        task: task,
                        archived: controller.currentTab.value == 2,
                        checked: controller.currentTab.value == 2
                            ? true.obs
                            : controller.checkedMap[key]!,
                        onComplete: (value) =>
                            _confirmComplete(context, task, value ?? false),
                        onTap: () {
                          controller.getSpecialTasksDetails(
                            specialTaskId: task.id.toString(),
                          );
                          Get.toNamed(AppRoutes.SPECIALTASKDETAILSSCREEN);
                        },
                        onLongPress: controller.currentTab.value == 2
                            ? null
                            : () => _showTaskActions(context, task),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, List<SpecialTaskModel>> _currentMap(
    SpecialTasksController controller,
  ) {
    switch (controller.currentTab.value) {
      case 1:
        return controller.filteredNoDateTasks;
      case 2:
        return controller.filteredArchivedTasks;
      default:
        return controller.filteredWeeklyTasks;
    }
  }

  void _confirmComplete(
    BuildContext context,
    SpecialTaskModel task,
    bool value,
  ) {
    if (controller.currentTab.value == 2) return;
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'areYouSure'.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      isLoading: controller.isLoading,
                      text: 'yes',
                      onPressed: () {
                        controller.checkedMap[task.id.toString()]!.value =
                            value;
                        controller.completedSpecialTasks(
                          context,
                          task.id.toString(),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: Colors.red,
                      width: double.infinity,
                      text: 'cancel'.tr,
                      textStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                      onPressed: Get.back,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskActions(BuildContext context, SpecialTaskModel task) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        child: Container(
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.currentTab.value == 0)
                  CustomCheckBox(
                    title: 'transferTask',
                    style: theme.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    value: controller.transferTask,
                    onChanged: (_) => controller.setOnlyOneTrue('transferTask'),
                    shape: const CircleBorder(),
                  ),
                if (controller.currentTab.value == 0)
                  Obx(
                    () => controller.transferTask.value
                        ? CustomCalendar(
                            isVisible: controller.transferTask,
                            onTap: () {},
                            selectedDay: controller.selectedDay,
                          )
                        : const SizedBox.shrink(),
                  ),
                CustomCheckBox(
                  title: 'deleteTask',
                  style: theme.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  value: controller.deleteTask,
                  onChanged: (_) => controller.setOnlyOneTrue('deleteTask'),
                  shape: const CircleBorder(),
                ),
                SizedBox(height: 3.h),
                CustomCheckBox(
                  title: 'deleteRepeatedTask',
                  style: theme.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  value: controller.deleteRepeatedTask,
                  onChanged: (_) =>
                      controller.setOnlyOneTrue('deleteRepeatedTask'),
                  shape: const CircleBorder(),
                ),
                SizedBox(height: 8.h),
                AppButton(
                  isSafeArea: false,
                  isLoading: controller.isLoading,
                  text: 'done',
                  onPressed: () => controller.cancelSpecialTasks(
                    specialTaskId: task.id.toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialTaskCard extends StatelessWidget {
  const _SpecialTaskCard({
    required this.task,
    required this.archived,
    required this.checked,
    required this.onComplete,
    required this.onTap,
    required this.onLongPress,
  });

  final SpecialTaskModel task;
  final bool archived;
  final RxBool checked;
  final ValueChanged<bool?> onComplete;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.operationalCardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.operationalNavy.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: checked.value,
                        onChanged: archived ? null : onComplete,
                        activeColor: AppColors.operationalPurple,
                        visualDensity: VisualDensity.compact,
                        shape: const CircleBorder(),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color:
                            AppColors.operationalPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: AppColors.operationalPurple,
                        size: 17.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    decoration: archived
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: isDark
                                        ? AppColors.whiteColor
                                        : AppColors.operationalNavy,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              _TimeLeftLabel(endTime: task.endDate),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${'dueDate'.tr}: ${showDateTime12(task.endDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              height: 1.2,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    TaskStatusBadge(status: task.status, compact: true),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.customGreyColor5,
                      size: 18.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.isFirst,
    required this.theme,
  });

  final String date;
  final bool isFirst;
  final TextStyle theme;

  @override
  Widget build(BuildContext context) {
    final todayKey = SpecialTasksController.dateKeyFrom(DateTime.now());
    final isToday = date == todayKey;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, isFirst ? 4.h : 8.h, 0, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, d/M/yyyy', Get.locale?.languageCode)
                      .format(DateTime.parse(date)),
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

class _TimeLeftLabel extends StatelessWidget {
  const _TimeLeftLabel({required this.endTime});

  final DateTime endTime;

  @override
  Widget build(BuildContext context) {
    final label = _formatTimeLeft(endTime);
    final color = _colorFor(endTime);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _formatTimeLeft(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'overdue'.tr;
    if (diff.inDays >= 1) return '${diff.inDays} ${'days'.tr}';
    if (diff.inHours >= 1) return '${diff.inHours} ${'hours'.tr}';
    final mins = diff.inMinutes.clamp(1, 59);
    return '$mins ${'minute'.tr}';
  }

  static Color _colorFor(DateTime end) {
    final hours = end.difference(DateTime.now()).inHours;
    if (hours <= 0) return AppColors.redColor;
    if (hours <= 24) return AppColors.customOrange3;
    return AppColors.customGreen1;
  }
}

class _SpecialTasksSkeletonSliver extends StatelessWidget {
  const _SpecialTasksSkeletonSliver();

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
            child: Row(
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
          ),
        );
      },
    );
  }
}
