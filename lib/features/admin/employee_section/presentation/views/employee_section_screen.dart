import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../widgets/create_qrcode.dart';
import '../widgets/employee_sections_list/employee_list.dart';
import '../widgets/employee_sections_list/employee_work_hours_list.dart';
import '../widgets/employee_sections_list/employee_section.dart';
import '../widgets/employee_sections_list/financial_dues_list.dart';
import '../widgets/employee_sections_list/loans_list.dart';
import '../widgets/attendance_report_filter_dialog.dart';
import '../widgets/employee_sections_list/work_hours_list.dart';
import '../widgets/employee_sections_list/admin_list.dart';
import '../widgets/attendance_overtime_request_card.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class EmployeeSectionScreen extends GetView<EmployeeSectionController> {
  const EmployeeSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        actions: [
          IconButton(
            tooltip: 'pointsGuideTitle'.tr,
            constraints: BoxConstraints.tightFor(width: 30.w, height: 32.h),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.redeem,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 19.sp,
            ),
            onPressed: canViewEmployeesPoints || canManageEmployeesRewardsRules
                ? () => Get.toNamed(AppRoutes.POINTSTABLE)
                : null,
          ),
          if (canViewEmployeesFinancial)
            _AppBarCompactIconButton(
              tooltip: 'entitlements'.tr,
              icon: Icons.account_balance_wallet_outlined,
              onPressed: controller.openEntitlementsTab,
            ),
          if (canManageEmployeesOrders)
            Obx(
              () => _AppBarBadgeIconButton(
                tooltip: 'loans'.tr,
                badgeCount: controller.pendingLoanRequestsCount,
                icon: Icons.payments_outlined,
                onPressed: controller.openLoansTab,
              ),
            ),
          Obx(() {
            final tab = controller.activeTab;
            final canShowAttendanceReport =
                tab == EmployeeSectionController.workHoursTab ||
                    (tab == EmployeeSectionController.employeeListTab &&
                        controller.isEmployeeListMergedWithWorkHours);
            if (!canShowAttendanceReport || !canViewEmployeesAttendance) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'attendanceReportAction'.tr,
              constraints: BoxConstraints.tightFor(width: 30.w, height: 32.h),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.assessment_outlined,
                size: 19.sp,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: () => showAttendanceReportFilterDialog(
                context,
                employees: controller.employeeService.workingTimesList.toList(),
              ),
            );
          }),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
                height: 38.h,
                horizontalPadding: 8.w,
                tabHorizontalPadding: 12.w,
                tabVerticalPadding: 7.h,
                tabHorizontalMargin: 3.w,
                fontSize: 12.sp,
              ),
            ),
            Obx(
              () {
                final tab = controller.activeTab;
                if (tab == EmployeeSectionController.employeeListTab) {
                  if (controller.isEmployeeListMergedWithWorkHours) {
                    return _MergedEmployeeWorkHoursSection(
                      controller: controller,
                    );
                  }
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () => controller.filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = controller.filteredEmployees[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: index == 0 ? 10.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: EmployeeList(employee: employee),
                            ),
                            SizedBox(
                              height: index ==
                                      controller.filteredEmployees.length - 1
                                  ? 20.h
                                  : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                if (tab == EmployeeSectionController.workHoursTab) {
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () => controller.filteredWorkingTimes.length,
                    itemBuilder: (context, index) {
                      final employeeWorkingTimes =
                          controller.filteredWorkingTimes[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: index == 0 ? 10.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: WorkHoursList(
                                employee: employeeWorkingTimes,
                              ),
                            ),
                            SizedBox(
                              height: index ==
                                      controller.filteredWorkingTimes.length - 1
                                  ? 20.h
                                  : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                if (tab == EmployeeSectionController.entitlementsTab) {
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () => controller.filteredFinancialDues.length,
                    itemBuilder: (context, index) {
                      final financialDues =
                          controller.filteredFinancialDues[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: index == 0 ? 10.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: FinancialDuesList(employee: financialDues),
                            ),
                            SizedBox(
                              height: index ==
                                      controller.filteredFinancialDues.length -
                                          1
                                  ? 20.h
                                  : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                if (tab == EmployeeSectionController.loansTab) {
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () => controller.filteredLoanList.length,
                    itemBuilder: (context, index) {
                      final financialDues = controller.filteredLoanList[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: index == 0 ? 10.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: LoansList(
                                employee: financialDues,
                                isOvertime: false,
                              ),
                            ),
                            SizedBox(
                              height: index ==
                                      controller.filteredLoanList.length - 1
                                  ? 20.h
                                  : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                if (tab == EmployeeSectionController.overtimeTab) {
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () =>
                        controller.attendanceOvertimeRequests.length +
                        controller.filteredOvertimeList.length,
                    itemBuilder: (context, index) {
                      final pendingCount =
                          controller.attendanceOvertimeRequests.length;
                      if (index < pendingCount) {
                        return AttendanceOvertimeRequestCard(
                          request: controller.attendanceOvertimeRequests[index],
                          controller: controller,
                        );
                      }
                      final loanIndex = index - pendingCount;
                      final financialDues =
                          controller.filteredOvertimeList[loanIndex];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 3.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: loanIndex == 0 ? 5.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: LoansList(
                                employee: financialDues,
                                isOvertime: true,
                              ),
                            ),
                            SizedBox(
                              height: loanIndex ==
                                      controller.filteredOvertimeList.length - 1
                                  ? 20.h
                                  : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                if (tab == EmployeeSectionController.adminsTab) {
                  return EmployeeSection(
                    isLoading: controller.isLoading,
                    onCount: () => controller.filteredAdmins.length,
                    itemBuilder: (context, index) {
                      final admin = controller.filteredAdmins[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: index == 0 ? 10.h : 0.h),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor4
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: AdminList(admin: admin),
                            ),
                            SizedBox(
                              height:
                                  index == controller.filteredAdmins.length - 1
                                      ? 20.h
                                      : 0.h,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 80.h),
            ),
          ],
        ),
      ),
      floatingActionButton: controller.canShowAddMenu
          ? CustomFloatingActionButton(
              isAddMenuOpen: controller.isAddMenuOpen,
              onTap: () => controller.toggleAddMenu(),
              opacityAnimation: controller.sizeAnimation,
              sizeAnimation: controller.opacityAnimation,
              addList: controller.visibleAddList,
              customWidget: canManageEmployeesAttendance
                  ? BuildAddMenuItem(
                      title: 'barcode',
                      iconAsset: AssetsManager.qrcode,
                      route: '',
                      onTap: () {
                        controller.generateQrCode(false);
                        controller.toggleAddMenu();
                        Get.dialog(const CreateQrcode());
                      },
                    )
                  : const SizedBox.shrink(),
            )
          : null,
    );
  }
}

class _MergedEmployeeWorkHoursSection extends StatelessWidget {
  const _MergedEmployeeWorkHoursSection({required this.controller});

  final EmployeeSectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: true,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final employees = controller.filteredEmployees;
      final workingTimes = controller.filteredWorkingTimes;
      if (employees.isEmpty && workingTimes.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: ShowNoData(),
        );
      }

      final workById = {
        for (final work in workingTimes) work.id: work,
      };
      final employeeIds = employees.map((employee) => employee.id).toSet();
      final unmatchedWorkingTimes = workingTimes
          .where((work) => !employeeIds.contains(work.id))
          .toList(growable: false);
      final itemCount = employees.length + unmatchedWorkingTimes.length;

      return SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < employees.length) {
            final employee = employees[index];
            return _EmployeeListCard(
              index: index,
              total: itemCount,
              child: EmployeeWorkHoursList(
                employee: employee,
                workingTimes: workById[employee.id],
              ),
            );
          }

          final workIndex = index - employees.length;
          return _EmployeeListCard(
            index: index,
            total: itemCount,
            child: WorkHoursList(employee: unmatchedWorkingTimes[workIndex]),
          );
        },
      );
    });
  }
}

class _EmployeeListCard extends StatelessWidget {
  const _EmployeeListCard({
    required this.index,
    required this.total,
    required this.child,
  });

  final int index;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 5.h,
      ),
      child: Column(
        children: [
          SizedBox(height: index == 0 ? 6.h : 0.h),
          Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor4
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: child,
          ),
          SizedBox(height: index == total - 1 ? 10.h : 0.h),
        ],
      ),
    );
  }
}

class _AppBarBadgeIconButton extends StatelessWidget {
  const _AppBarBadgeIconButton({
    required this.tooltip,
    required this.badgeCount,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final int badgeCount;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 30.w,
        height: 32.h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              constraints: BoxConstraints.tightFor(width: 30.w, height: 32.h),
              padding: EdgeInsets.zero,
              icon: Icon(
                icon,
                size: 19.sp,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: onPressed,
            ),
            if (badgeCount > 0)
              PositionedDirectional(
                top: 1.h,
                end: 0,
                child: Container(
                  constraints: BoxConstraints(minWidth: 15.w),
                  height: 15.h,
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.redColor,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: TextStyle(
                      fontSize: 8.sp,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppBarCompactIconButton extends StatelessWidget {
  const _AppBarCompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: BoxConstraints.tightFor(width: 30.w, height: 32.h),
      padding: EdgeInsets.zero,
      icon: Icon(
        icon,
        size: 19.sp,
        color: ThemeService.isDark.value
            ? AppColors.primaryColor
            : AppColors.secondaryColor,
      ),
      onPressed: onPressed,
    );
  }
}
