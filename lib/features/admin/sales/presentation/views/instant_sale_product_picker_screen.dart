import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../widgets/new_instant_sale/instant_sale_cart_sheet.dart';
import '../widgets/new_instant_sale/instant_sale_package_card.dart';
import '../widgets/new_instant_sale/instant_sale_product_card.dart';

/// شاشة اختيار المنتجات (سلة) قبل إتمام البيع الفوري.
class InstantSaleProductPickerScreen extends StatefulWidget {
  const InstantSaleProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<InstantSaleProductPickerScreen> createState() =>
      _InstantSaleProductPickerScreenState();
}

class _InstantSaleProductPickerScreenState
    extends State<InstantSaleProductPickerScreen> {
  SalesController get controller => Get.find<SalesController>();
  final _searchController = TextEditingController();

  static const int _rows = 4;
  static const int _visibleColumns = 4;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['freshInstantSale'] == true) {
      controller.resetInstantSaleForm();
      controller.isPackageSale.value = false;
    }
    _searchController.text = controller.instantSaleProductSearch.value;
    if (controller.products.isEmpty) {
      controller.getAllProducts();
    }
    controller.loadOfferPackagesForSale();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'instantSalePickProducts',
        action: false,
        actions: [
          _CartAppBarButton(
            onTap: () => showInstantSaleCartSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'instantSaleSearchProductsAndPackages'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              onChanged: (v) => controller.instantSaleProductSearch.value = v,
            ),
          ),
          Expanded(
            child: Obx(() {
              final _ = controller.productsListVersion.value;
              final saving = controller.savingProductPrice.value;
              final loading = controller.productsLoading.value;

              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final packages = controller.filteredPackagesForPicker;
              final products = controller.filteredProductsForPicker;
              final total = controller.pickerGridItemCount;

              if (total == 0) {
                return Center(
                  child: Text(
                    'noData'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final hGap = 6.w;
                      final vGap = 6.h;
                      final padH = 10.w;
                      final gridW = constraints.maxWidth - padH * 2;
                      final gridH = constraints.maxHeight;
                      final cellW = (gridW - hGap * (_visibleColumns - 1)) /
                          _visibleColumns;
                      final cellH = (gridH - vGap * (_rows - 1)) / _rows;
                      final aspectRatio = cellH / cellW;

                      return GridView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: padH),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _rows,
                          mainAxisSpacing: hGap,
                          crossAxisSpacing: vGap,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: total,
                        itemBuilder: (_, i) {
                          if (i < packages.length) {
                            final pkg = packages[i];
                            return InstantSalePackageCard(
                              key: ValueKey('picker_pkg_${pkg.id}'),
                              package: pkg,
                            );
                          }
                          final product = products[i - packages.length];
                          return InstantSaleProductCard(
                            key: ValueKey('picker_${product.id}'),
                            product: product,
                          );
                        },
                      );
                    },
                  ),
                  if (saving)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.65),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final count = controller.cartTotalPieces;
        final lines = controller.cartDistinctCount;
        final packageSelected = controller.hasSelectedPackage;
        final selectionCount = controller.pickerSelectionCount;
        final canContinue = controller.canContinueFromPicker;
        return SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => showInstantSaleCartSheet(context),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.primaryColor,
                          size: 28.sp,
                        ),
                        if (selectionCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: packageSelected
                                    ? const Color(0xFFE65100)
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18.w,
                                minHeight: 18.w,
                              ),
                              child: Text(
                                '$selectionCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        packageSelected && lines > 0
                            ? 'instantSalePackageAndProducts'.tr
                            : packageSelected
                                ? 'saleOfferPackage'.tr
                                : '${'instantSaleCart'.tr} ($lines)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        packageSelected && lines > 0
                            ? '${controller.selectedOfferPackage?.name ?? ''} + $count ${'instantSalePieces'.tr}'
                            : packageSelected
                                ? (controller.selectedOfferPackage?.name ?? '')
                                : '$count ${'instantSalePieces'.tr}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: canContinue
                        ? controller.openInstantSaleCheckout
                        : null,
                    child: Text(
                      'instantSaleContinue'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CartAppBarButton extends StatelessWidget {
  const _CartAppBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    return Obx(() {
      final _ = controller.cartRevision.value;
      final __ = controller.selectedPackageId.value;
      final n = controller.pickerSelectionCount;
      final packageOnly = controller.hasSelectedPackage && n == 1;
      return IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            if (n > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: packageOnly
                        ? const Color(0xFFE65100)
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.w,
                  ),
                  child: Text(
                    '$n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
