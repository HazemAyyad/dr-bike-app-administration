import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            onSelected: controller.downloadExpenseReport,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pdf', child: Text('تنزيل PDF')),
              PopupMenuItem(value: 'xlsx', child: Text('تنزيل Excel')),
              PopupMenuItem(value: 'csv', child: Text('تنزيل CSV')),
            ],
          ),
          SizedBox(width: 8.w),
        ],
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
          SliverToBoxAdapter(
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                child: Row(
                  children: [
                    _ExpenseTypeChip(
                      label: 'الكل',
                      value: '',
                      selected: controller.expenseTypeFilter.value.isEmpty,
                      onSelected: controller.setExpenseTypeFilter,
                    ),
                    _ExpenseTypeChip(
                      label: 'عمومية',
                      value: 'general',
                      selected: controller.expenseTypeFilter.value == 'general',
                      onSelected: controller.setExpenseTypeFilter,
                    ),
                    _ExpenseTypeChip(
                      label: 'رواتب',
                      value: 'salary',
                      selected: controller.expenseTypeFilter.value == 'salary',
                      onSelected: controller.setExpenseTypeFilter,
                    ),
                    _ExpenseTypeChip(
                      label: 'إتلاف',
                      value: 'destruction',
                      selected:
                          controller.expenseTypeFilter.value == 'destruction',
                      onSelected: controller.setExpenseTypeFilter,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
              child: SearchBar(
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                leading: const Icon(Icons.search),
                hintText: 'search'.tr,
                backgroundColor: WidgetStateProperty.all(
                  ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor7,
                ),
                onChanged: (value) => controller.searchBar(value),
              ),
            ),
          ),
          GetBuilder<ExpensesController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const _ExpensesSkeletonSliver();
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
                        ? controller.expensesFilter.keys
                            .toList()
                            .reversed
                            .toList()[index]
                        : controller.destructionsFilter.keys
                            .toList()
                            .reversed
                            .toList()[index];

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
          controller.boxIdController.clear();
          controller.expenseDateController.text =
              DateTime.now().toIso8601String().split('T').first;
          controller.expenseType.value = 'general';
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

class _ExpenseTypeChip extends StatelessWidget {
  const _ExpenseTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _ExpensesSkeletonSliver extends StatelessWidget {
  const _ExpensesSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      sliver: SliverList.builder(
        itemCount: 7,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              SkeletonBlock(width: 58.w, height: 58.h, radius: 12),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 150.w, height: 14.h, radius: 6),
                    SizedBox(height: 10.h),
                    SkeletonBlock(width: 95.w, height: 11.h, radius: 5),
                  ],
                ),
              ),
              SkeletonBlock(width: 62.w, height: 30.h, radius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
