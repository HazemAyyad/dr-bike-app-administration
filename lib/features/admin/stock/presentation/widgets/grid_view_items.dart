import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';

class GridViewItems extends GetView<StockController> {
  const GridViewItems({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final isEmpty = controller.currentTab.value == 0
          ? controller.allProducts.isEmpty
          : controller.currentTab.value == 1
              ? controller.allClearances.isEmpty
              : controller.allCombinations.isEmpty;

      if (isEmpty) {
        return const SliverFillRemaining(
          child: ShowNoData(),
        );
      }

      return SliverList(
        delegate: SliverChildListDelegate(
          [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Obx(() {
                final items = controller.currentTab.value == 0
                    ? controller.allProducts
                    : controller.currentTab.value == 1
                        ? controller.allClearances
                        : controller.allCombinations;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return BuildProductCard(
                      product: product,
                      isCloseouts: false,
                    );
                  },
                );
              }),
            ),
            // SizedBox(height: 20.h),
            if (controller.isLoadingMore.value)
              const Center(child: CircularProgressIndicator()),
            SizedBox(height: 50.h),
          ],
        ),
      );
    });
  }
}
