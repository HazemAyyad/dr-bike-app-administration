import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';
import 'stock_product_grid_layout.dart';
import 'stock_location_tab.dart';
import 'stock_offer_packages_tab.dart';

class GridViewItems extends GetView<StockController> {
  const GridViewItems({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.currentTab.value == 4) {
        return const SliverToBoxAdapter(
          child: StockOfferPackagesTab(),
        );
      }
      if (controller.currentTab.value == 3) {
        return const SliverToBoxAdapter(
          child: StockLocationTab(),
        );
      }

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

                final aspectRatio =
                    StockProductGridLayout.aspectRatioForTab(
                        controller.currentTab.value);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      StockProductGridLayout.delegate(
                    aspectRatio: aspectRatio,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return Align(
                      alignment: Alignment.topCenter,
                      child: BuildProductCard(
                        product: product,
                        isCloseouts: false,
                      ),
                    );
                  },
                );
              }),
            ),
            if (controller.isLoadingMore.value)
              const Center(child: CircularProgressIndicator()),
            SizedBox(height: 50.h),
          ],
        ),
      );
    });
  }
}
