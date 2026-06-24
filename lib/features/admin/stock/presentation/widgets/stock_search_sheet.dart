import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';
import 'stock_product_grid_layout.dart';
import 'stock_results_count_banner.dart';

/// Context passed to product cards opened from the stock search bottom sheet.
class StockSearchContext {
  const StockSearchContext({
    required this.isCloseouts,
    this.borderRadius,
    this.newComposition,
    this.productIdController,
    this.productNameController,
  });

  final bool isCloseouts;
  final BorderRadius? borderRadius;
  final NewCompositionModel? newComposition;
  final TextEditingController? productIdController;
  final TextEditingController? productNameController;
}

class _StockSearchHistorySection extends GetView<StockController> {
  const _StockSearchHistorySection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.stockSearchHistory;
      if (history.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Text(
            'stockSearchHint'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'stockSearchRecent'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearStockSearchHistory,
                  child: Text('stockSearchClearHistory'.tr),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            ...history.map(
              (query) => Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  leading: Icon(
                    Icons.schedule,
                    size: 20.sp,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor.withValues(alpha: 0.7)
                        : AppColors.secondaryColor.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  trailing: IconButton(
                    tooltip: 'delete'.tr,
                    icon: Icon(Icons.close, size: 18.sp),
                    onPressed: () =>
                        controller.removeStockSearchHistoryItem(query),
                  ),
                  onTap: () => controller.applyStockSearchHistory(query),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

void openStockSearchSheet({
  required StockController controller,
  required StockSearchContext searchContext,
  bool autofocus = true,
}) {
  if (Get.isBottomSheetOpen == true) {
    return;
  }

  controller.loadStockSearchHistory();
  controller.stockSearchActiveQuery.value =
      controller.stockSearchQueryController.text;

  Get.bottomSheet(
    DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.stockSearchQueryController,
                      autofocus: autofocus,
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Obx(() {
                          if (controller.stockSearchActiveQuery.value
                              .trim()
                              .isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            tooltip: 'clear'.tr,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.stockSearchQueryController.clear();
                              controller.onStockSearchQueryChanged('');
                            },
                          );
                        }),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 24.w,
                        ),
                      ),
                      onChanged: (value) {
                        controller.onStockSearchQueryChanged(value);
                        if (value.trim().isEmpty) {
                          return;
                        }
                        controller.getSearchProducts(name: value);
                      },
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            Obx(() {
              final query = controller.stockSearchActiveQuery.value.trim();

              if (query.isEmpty) {
                return const SliverToBoxAdapter(
                  child: _StockSearchHistorySection(),
                );
              }

              if (controller.isSearchLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.searchProducts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: const StockResultsCountBanner(count: 0),
                      ),
                      const Expanded(child: ShowNoData()),
                    ],
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 8.h),
                  child: StockResultsCountBanner(
                    count: controller.searchProducts.length,
                  ),
                ),
              );
            }),
            Obx(() {
              final query = controller.stockSearchActiveQuery.value.trim();
              if (query.isEmpty ||
                  controller.isSearchLoading.value ||
                  controller.searchProducts.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = controller.searchProducts[index];
                      return Align(
                        alignment: Alignment.topCenter,
                        child: BuildProductCard(
                          product: product,
                          isCloseouts: searchContext.isCloseouts,
                          newComposition: searchContext.newComposition,
                          productIdController: searchContext.productIdController,
                          productNameController:
                              searchContext.productNameController,
                          searchContext: searchContext,
                        ),
                      );
                    },
                    childCount: controller.searchProducts.length,
                  ),
                  gridDelegate: StockProductGridLayout.delegate(
                    aspectRatio: StockProductGridLayout.aspectRatioForTab(0),
                  ),
                ),
              );
            }),
          ],
        );
      },
    ),
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: ThemeService.isDark.value
        ? AppColors.darkColor
        : AppColors.whiteColor,
  );
}

void reopenStockSearchSheetIfNeeded({
  required StockController controller,
  required StockSearchContext searchContext,
}) {
  if (controller.stockSearchQueryController.text.trim().isEmpty) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    openStockSearchSheet(
      controller: controller,
      searchContext: searchContext,
      autofocus: false,
    );
  });
}
