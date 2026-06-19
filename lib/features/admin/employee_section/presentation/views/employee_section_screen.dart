import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../widgets/create_qrcode.dart';
import '../widgets/employee_sections_list/employee_list.dart';
import '../widgets/employee_sections_list/employee_section.dart';
import '../widgets/employee_sections_list/financial_dues_list.dart';
import '../widgets/employee_sections_list/loans_list.dart';
import '../widgets/attendance_report_filter_dialog.dart';
import '../widgets/employee_sections_list/work_hours_list.dart';
import '../widgets/attendance_overtime_request_card.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class EmployeeSectionScreen extends GetView<EmployeeSectionController> {
  const EmployeeSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeSection',
        actions: [
          IconButton(
            tooltip: 'pointsGuideTitle'.tr,
            icon: Icon(
              Icons.redeem,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 25.sp,
            ),
            onPressed: () => Get.toNamed(AppRoutes.POINTSTABLE),
          ),
          IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 27.sp,
            ),
            onPressed: () {
              controller.getLogs();
              Get.toNamed(AppRoutes.ACTIVITYLOGSCREEN);
            },
          ),
          IconButton(
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 22.sp,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
            onPressed: () {
              showCustomDialog(
                context,
                // fromDateController: controller.fromDateController,
                // toDateController: controller.toDateController,
                employeeNameController: controller.employeeNameController,
                label: 'employeeName',
                onPressed: () {
                  controller.filterLists();
                },
              );
            },
          ),
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
            ),
          ),
          Obx(
            () {
              if (controller.currentTab.value != 1) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                      ),
                      onPressed: () => showAttendanceReportFilterDialog(
                        context,
                        employees: controller
                            .employeeService.workingTimesList
                            .toList(),
                      ),
                      icon: const Icon(Icons.assessment_outlined),
                      label: Text('attendanceReportAction'.tr),
                    ),
                  ),
                ),
              );
            },
          ),
          Obx(
            () {
              final tab = controller.currentTab.value;
              if (tab == 0) {
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
              if (tab == 1) {
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
              if (tab == 2) {
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
                                    controller.filteredFinancialDues.length - 1
                                ? 20.h
                                : 0.h,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              if (tab == 3) {
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
                      horizontal: 24.w,
                      vertical: 5.h,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: loanIndex == 0 ? 10.h : 0.h),
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
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 80.h),
          ),
        ],
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.addList,
        customWidget: BuildAddMenuItem(
          title: 'barcode',
          iconAsset: AssetsManager.qrcode,
          route: '',
          onTap: () {
            controller.generateQrCode(false);
            controller.toggleAddMenu();
            Get.dialog(const CreateQrcode());
          },
        ),
      ),
    );
  }
}
