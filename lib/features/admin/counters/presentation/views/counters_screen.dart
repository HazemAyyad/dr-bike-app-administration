import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/counters_controller.dart';
import '../controllers/counters_serves.dart';
import '../widgets/filter.dart';

class CountersScreen extends GetView<CountersController> {
  const CountersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        dsibalBack: true,
        title: 'countersAndStatisticsAndReports',
        action: false,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        actions: const [Filter()],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                ],
              ),
            );
          }
          final reportInformationData =
              CountersServes().reportInformationData.value!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.r),
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'debts',
                                  context: context,
                                );
                              },
                              title: 'debtsWeOwe',
                              imageicon: AssetsManager.cashIcon,
                              value: reportInformationData.totalDebtsWeOwe,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'instant_sales',
                                  context: context,
                                );
                              },
                              title: 'totalSaless',
                              imageicon: AssetsManager.moneyIcon,
                              value: reportInformationData.totalSales,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                // controller.downloadReport(
                                //   type: 'net_profit',
                                //   context: context,
                                // );
                              },
                              title: 'netProfit',
                              imageicon: AssetsManager.cashIcon7,
                              value: reportInformationData.profits,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'boxes',
                                  context: context,
                                );
                              },
                              title: 'totalBoxes',
                              imageicon: AssetsManager.cashIcon5,
                              value: reportInformationData.totalBoxes,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'checks',
                                  context: context,
                                );
                              },
                              title: 'totalChecks',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData.totalChecks,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'bills',
                                  context: context,
                                );
                              },
                              show: true,
                              title: 'purchasesValue',
                              imageicon: AssetsManager.cashIcon4,
                              value: reportInformationData.totalExpenses,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'people',
                                  context: context,
                                );
                              },
                              show: true,
                              title: 'numberOfPeople',
                              imageicon: AssetsManager.usersIcon,
                              value: reportInformationData.numberOfPeople,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'projects',
                                  context: context,
                                );
                              },
                              show: true,
                              title: 'numberOfProjects',
                              imageicon: AssetsManager.cashIcon5,
                              value: reportInformationData.numberOfProjects,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'employees',
                                  context: context,
                                );
                              },
                              show: true,
                              title: 'numberOfEmployees',
                              imageicon: AssetsManager.usersIcon,
                              value: reportInformationData.numberOfEmployees,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'expenses',
                                  context: context,
                                );
                              },
                              title: 'totalExpensess',
                              imageicon: AssetsManager.cashIcon6,
                              value: reportInformationData.totalExpenses,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'returns',
                                  context: context,
                                );
                              },
                              show: true,
                              title: 'purchaseReturns',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData.totalReturns,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                // controller.downloadReport(
                                //   type: 'net_profit',
                                //   context: context,
                                // );
                              },
                              show: true,
                              title: 'costOfGoods',
                              imageicon: AssetsManager.cashIcon2,
                              value: reportInformationData.totalGoods,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                // controller.downloadReport(
                                //   type: 'net_profit',
                                //   context: context,
                                // );
                              },
                              title: 'shopCapital',
                              imageicon: AssetsManager.cashIcon,
                              value: reportInformationData.shopCapital,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                // controller.downloadReport(
                                //   type: 'net_profit',
                                //   context: context,
                                // );
                              },
                              title: 'netShopCapital',
                              imageicon: AssetsManager.cashIcon,
                              value: reportInformationData.netShopCapital,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'employee_tasks',
                                  context: context,
                                );
                              },
                              title: 'completedDailyTasks',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData
                                  .completedEmployeeTasksDaily,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'employee_tasks',
                                  context: context,
                                );
                              },
                              title: 'incompletedDailyTasks',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData
                                  .incompletedEmployeeTasksDaily,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'employee_tasks',
                                  context: context,
                                );
                              },
                              title: 'completedMonthlyTasks',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData
                                  .completedEmployeeTasksMonthly,
                              subtitle: '',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                controller.downloadReport(
                                  type: 'employee_tasks',
                                  context: context,
                                );
                              },
                              title: 'incompletedMonthlyTasks',
                              imageicon: AssetsManager.cashIcon3,
                              value: reportInformationData
                                  .incompletedEmployeeTasksMonthly,
                              subtitle: '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
