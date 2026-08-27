import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/assets_controller.dart';
import '../../widgets/assets_widget/assets_card.dart';
import '../../widgets/assets_widget/assets_data.dart';
import '../../widgets/financial_skeletons.dart';

class AssetsScreen extends GetView<AssetsController> {
  const AssetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'assets',
        fromDateController: controller.fromController,
        toDateController: controller.toController,
        action: false,
        onPressedFilter: () {
          controller.filterAssetsByDate();
        },
      ),
      body: CustomScrollView(
        slivers: [
          const AssetsData(),
          SliverToBoxAdapter(
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Row(
                  children: [
                    _AssetStatusChip(
                      label: 'الكل',
                      value: '',
                      selected: controller.assetStatusFilter.value.isEmpty,
                      onSelected: controller.setAssetStatusFilter,
                    ),
                    _AssetStatusChip(
                      label: 'فعّال',
                      value: 'active',
                      selected: controller.assetStatusFilter.value == 'active',
                      onSelected: controller.setAssetStatusFilter,
                    ),
                    _AssetStatusChip(
                      label: 'مكتمل الإهلاك',
                      value: 'fully_depreciated',
                      selected: controller.assetStatusFilter.value ==
                          'fully_depreciated',
                      onSelected: controller.setAssetStatusFilter,
                    ),
                    _AssetStatusChip(
                      label: 'تم إهلاك الشهر',
                      value: 'depreciated_this_month',
                      selected: controller.assetStatusFilter.value ==
                          'depreciated_this_month',
                      onSelected: controller.setAssetStatusFilter,
                    ),
                    _AssetStatusChip(
                      label: 'بانتظار إهلاك الشهر',
                      value: 'pending_this_month',
                      selected: controller.assetStatusFilter.value ==
                          'pending_this_month',
                      onSelected: controller.setAssetStatusFilter,
                    ),
                  ],
                ),
              ),
            ),
          ),
          GetBuilder<AssetsController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const FinancialListSkeletonSliver();
              }
              if (controller.assetsFilter.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ShowNoData(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final month = controller.assetsFilter.keys
                        .toList()
                        .reversed
                        .toList()[index];
                    final assets =
                        controller.assetsFilter[month]!.reversed.toList();
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 5.h, horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: index == 0 ? 5 : 0.h),
                          Row(
                            children: [
                              Text(
                                month.toString(),
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
                          ...assets.map((asset) => AssetsCard(asset: asset)),
                        ],
                      ),
                    );
                  },
                  childCount: controller.assetsFilter.values.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 55.h,
        width: 55.w,
        child: FloatingActionButton(
          onPressed: () {
            controller.isEditing(false);
            controller.editAsset();
            Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
          },
          backgroundColor: AppColors.secondaryColor,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: AppColors.whiteColor,
            size: 42.sp,
          ),
        ),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _AssetStatusChip extends StatelessWidget {
  const _AssetStatusChip({
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
