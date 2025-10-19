import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';

class SearchWidget extends GetView<StockController> {
  const SearchWidget({
    Key? key,
    required this.isCloseouts,
    this.borderRadius,
    this.newComposition,
    this.productIdController,
    this.productNameController,
  }) : super(key: key);

  final bool isCloseouts;
  final BorderRadius? borderRadius;
  final NewCompositionModel? newComposition;
  final TextEditingController? productIdController;
  final TextEditingController? productNameController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'search'.tr,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onTap: () {
        Get.bottomSheet(
          DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
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
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'search'.tr,
                              prefixIcon: const Icon(Icons.search),
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
                              controller.searchProducts.clear();
                              controller.getSearchProducts(name: value);
                              value.isEmpty
                                  ? controller.searchProducts.clear()
                                  : null;
                            },
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                  GetBuilder<StockController>(builder: (controller) {
                    if (controller.isProductLoading.value) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.searchProducts.isEmpty) {
                      return const SliverFillRemaining(
                        child: ShowNoData(),
                      );
                    }
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = controller.searchProducts[index];
                            return BuildProductCard(
                              product: product,
                              isCloseouts: isCloseouts,
                              newComposition: newComposition,
                              productIdController: productIdController,
                              productNameController: productNameController,
                            );
                          },
                          childCount: controller.searchProducts.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 0.75,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          isScrollControlled: true,
          backgroundColor: ThemeService.isDark.value
              ? AppColors.darkColor
              : AppColors.whiteColor,
        );
      },
    );
  }
}
