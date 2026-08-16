import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/follow_up_controller.dart';
import '../widgets/follow_up_widget.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class CurrentFollowUpScreen extends GetView<FollowUpController> {
  const CurrentFollowUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'followUpDepartment',
        action: false,
        actions: [
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
          physics: kRefreshableScrollPhysics,
          slivers: [
            GetBuilder<FollowUpController>(
              id: 'searchBar',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          child: SearchBar(
                            controller: controller.employeeNameController,
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
                            onChanged: controller.searchBar,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            const SliverToBoxAdapter(child: _FollowUpQuickFilters()),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: GetBuilder<FollowUpController>(
                  builder: (c) => Text(
                    '${'total'.tr}: ${c.visibleFilteredCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            const FollowUpWidget(),
            SliverToBoxAdapter(child: SizedBox(height: 30.h)),
          ],
        ),
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.resetData();
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FollowUpQuickFilters extends GetView<FollowUpController> {
  const _FollowUpQuickFilters();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      builder: (controller) {
        final filters = [
          _FollowUpFilterData(
            value: FollowUpController.followUpFilterAll,
            label: 'allFollowUps'.tr,
            icon: Icons.dashboard_customize_outlined,
            color: AppColors.operationalPurple,
            count: controller.totalFilteredCount,
          ),
          _FollowUpFilterData(
            value: FollowUpController.followUpFilterActive,
            label: 'activeFollowUps'.tr,
            icon: Icons.pending_actions_outlined,
            color: AppColors.primaryColor,
            count: controller.activeSectionsCount,
          ),
          _FollowUpFilterData(
            value: FollowUpController.followUpFilterDelivered,
            label: 'deliveredFollowUps'.tr,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.customGreen1,
            count: controller.archivedCount,
          ),
          _FollowUpFilterData(
            value: FollowUpController.followUpFilterCanceled,
            label: 'canceledFollowUps'.tr,
            icon: Icons.block_rounded,
            color: AppColors.redColor,
            count: controller.canceledCount,
          ),
          _FollowUpFilterData(
            value: FollowUpController.followUpFilterDeleted,
            label: 'deletedFollowUps'.tr,
            icon: Icons.delete_outline_rounded,
            color: AppColors.customGreyColor5,
            count: controller.deletedCount,
          ),
        ];

        return SizedBox(
          height: 48.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final selected =
                  controller.followUpViewFilter.value == filter.value;
              return _FollowUpFilterChip(
                data: filter,
                selected: selected,
                onTap: () => controller.setFollowUpViewFilter(filter.value),
              );
            },
          ),
        );
      },
    );
  }
}

class _FollowUpFilterData {
  const _FollowUpFilterData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int count;
}

class _FollowUpFilterChip extends StatelessWidget {
  const _FollowUpFilterChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _FollowUpFilterData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : ThemeService.isDark.value
            ? Colors.white70
            : data.color;

    return Tooltip(
      message: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: selected ? data.color : data.color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? data.color : data.color.withValues(alpha: 0.22),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(data.icon, size: 20.sp, color: foreground),
              if (data.count > 0)
                PositionedDirectional(
                  top: -5.h,
                  end: -5.w,
                  child: Container(
                    constraints:
                        BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.count > 99 ? '99+' : '${data.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
