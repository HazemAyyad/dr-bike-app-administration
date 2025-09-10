import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/expenses_models/destruction_model.dart';
import '../../../data/models/expenses_models/expense_data_model.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/expenses_widgets/destruction_card.dart';
import '../../widgets/expenses_widgets/expenses_card.dart';

class ExpensesScreen extends GetView<ExpensesController> {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'theExpenses',
        fromDateController: controller.fromController,
        toDateController: controller.toController,
        action: false,
        onPressedFilter: () {
          controller.filterExpensesByDate();
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          GetBuilder<ExpensesController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.currentTab.value == 0
                  ? controller.expensesFilter.isEmpty
                  : controller.destructionsFilter.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ShowNoData(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final month = controller.currentTab.value == 0
                        ? controller.expensesFilter.keys.toList()[index]
                        : controller.destructionsFilter.keys.toList()[index];

                    final data = controller.currentTab.value == 0
                        ? controller.expensesFilter[month]!.reversed.toList()
                        : controller.destructionsFilter[month]!.reversed
                            .toList();

                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 5.h, horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: index == 0 ? 10 : 0.h),
                          Row(
                            children: [
                              Text(
                                month,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.sp,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Container(
                            height: 1.h,
                            width: double.infinity,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 10.h),
                          ...data.map(
                            (expense) => controller.currentTab.value == 0
                                ? ExpensesCard(expense: expense as ExpenseModel)
                                : DestructionCard(
                                    data: expense as DestructionModel,
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.expensesFilter.length
                      : controller.destructionsFilter.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () {
          controller.toggleAddMenu();
          controller.isEditing.value = false;
          controller.expenseNameController.clear();
          controller.expensePriceController.clear();
          controller.expenseNoteController.clear();
          controller.paymentMethodController.clear();
          controller.invoiceFile.clear();
          controller.expensesFile.clear();
        },
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.addList,
      ),
    );
  }
}
