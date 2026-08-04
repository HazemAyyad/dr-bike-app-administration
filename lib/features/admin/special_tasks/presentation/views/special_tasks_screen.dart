import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/special_tasks_controller.dart';
import '../widgets/tasks_list.dart';

class SpecialTasksScreen extends GetView<SpecialTasksController> {
  const SpecialTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'privateTasks',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedFilter: () => controller.filterLists(true),
        action: false,
        actions: [
          _SpecialTaskAppBarTabs(controller: controller),
          Obx(
            () => IconButton(
              tooltip: 'search'.tr,
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: kRefreshableScrollPhysics,
          slivers: [
            GetBuilder<SpecialTasksController>(
              id: 'specialSearchBar',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          child: SearchBar(
                            controller: controller.searchController,
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                tooltip: 'cancel'.tr,
                                onPressed: controller.closeSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                            hintText: 'search'.tr,
                            backgroundColor: WidgetStateProperty.all(
                              ThemeService.isDark.value
                                  ? AppColors.customGreyColor
                                  : AppColors.customGreyColor7,
                            ),
                            onChanged: controller.onSearchChanged,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SpecialTasksViewModeBar()),
            const TasksList(),
            SliverToBoxAdapter(child: SizedBox(height: 72.h)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'addNewPravateTask', 'isEdit': false},
          );
        },
        backgroundColor: AppColors.secondaryColor,
        child: Icon(Icons.add, color: Colors.white, size: 28.sp),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _SpecialTaskAppBarTabs extends StatelessWidget {
  const _SpecialTaskAppBarTabs({required this.controller});

  final SpecialTasksController controller;

  IconData _iconForIndex(int index) {
    switch (index) {
      case 1:
        return Icons.event_busy_outlined;
      case 2:
        return Icons.archive_outlined;
      default:
        return Icons.view_week_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < controller.tabs.length; i++)
            _SpecialTaskAppBarTab(
              icon: _iconForIndex(i),
              label: controller.tabs[i].tr,
              selected: controller.currentTab.value == i,
              onTap: () => controller.changeTab(i),
            ),
        ],
      ),
    );
  }
}

class _SpecialTaskAppBarTab extends StatelessWidget {
  const _SpecialTaskAppBarTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : ThemeService.isDark.value
            ? Colors.white70
            : AppColors.secondaryColor;
    return Tooltip(
      message: label,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 34.w, minHeight: 40.h),
        onPressed: onTap,
        icon: Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18.sp, color: fg),
        ),
      ),
    );
  }
}

class _SpecialTasksViewModeBar extends GetView<SpecialTasksController> {
  const _SpecialTasksViewModeBar();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SpecialTasksController>(
      id: 'specialPeriodBar',
      builder: (controller) {
        return Obx(() {
          final mode = controller.tasksViewMode.value;
          return Container(
            margin: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: ThemeService.isDark.value
                    ? Colors.white10
                    : AppColors.operationalCardBorder,
              ),
            ),
            child: Row(
              children: [
                _navButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => controller.changePeriod(false),
                ),
                SizedBox(width: 2.w),
                _modeButton(
                  icon: Icons.today_outlined,
                  label: 'tasksViewDaily'.tr,
                  selected: mode == SpecialTasksController.tasksViewDaily,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewDaily,
                  ),
                ),
                _modeButton(
                  icon: Icons.view_week_outlined,
                  label: 'tasksViewWeekly'.tr,
                  selected: mode == SpecialTasksController.tasksViewWeekly,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewWeekly,
                  ),
                ),
                _modeButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'tasksViewMonthly'.tr,
                  selected: mode == SpecialTasksController.tasksViewMonthly,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewMonthly,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Tooltip(
                    message: 'selectDate'.tr,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => _pickPeriodAnchor(context),
                      child: Container(
                        height: 32.h,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          controller.compactPeriodLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.operationalNavy,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                _navButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => controller.changePeriod(true),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _pickPeriodAnchor(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: Get.locale,
    );
    if (picked != null) {
      controller.jumpToPeriod(picked);
    }
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fg = selected
        ? Colors.white
        : ThemeService.isDark.value
            ? Colors.white70
            : AppColors.operationalNavy;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34.w,
          height: 32.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: fg),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: SizedBox(
        width: 30.w,
        height: 32.h,
        child: Icon(
          icon,
          color: AppColors.operationalPurple,
          size: 22.sp,
        ),
      ),
    );
  }
}
