import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../../data/models/all_stock_products_model.dart';
import 'product_location_badge.dart';
import 'stock_product_grid_layout.dart';
import 'stock_search_sheet.dart';
import '../controllers/stock_controller.dart';

void _dismissBlockingOverlays() {
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }
  while (Get.isDialogOpen == true) {
    Get.back();
  }
}

class BuildProductCard extends GetView<StockController> {
  const BuildProductCard({
    Key? key,
    required this.product,
    required this.isCloseouts,
    this.newComposition,
    this.productIdController,
    this.productNameController,
    this.searchContext,
  }) : super(key: key);

  final AllStockProductsModel product;
  final bool isCloseouts;
  final NewCompositionModel? newComposition;
  final TextEditingController? productIdController;
  final TextEditingController? productNameController;
  final StockSearchContext? searchContext;

  Future<void> _openProductDetails() async {
    final fromSearch = searchContext != null;

    if (fromSearch && Get.isBottomSheetOpen == true) {
      Get.back();
    }

    await controller.getProductDetails(productId: product.productId);
    await Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN);
    _dismissBlockingOverlays();

    if (fromSearch &&
        controller.stockSearchQueryController.text.trim().isNotEmpty) {
      reopenStockSearchSheetIfNeeded(
        controller: controller,
        searchContext: searchContext!,
      );
    }
  }

  String _formatCostPrice() {
    final value = product.costPrice;
    if (value == null || value <= 0) return '-';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Future<void> _showCostPriceDialog(BuildContext context) async {
    var rawCostPrice = product.costPrice == null || product.costPrice! <= 0
        ? ''
        : _formatCostPrice();
    const dialogBackground = Colors.white;
    final textColor = AppColors.secondaryColor;
    await Get.dialog(
      AlertDialog(
        backgroundColor: dialogBackground,
        surfaceTintColor: dialogBackground,
        title: Text(
          'costPrice'.tr,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextFormField(
          initialValue: rawCostPrice,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: textColor),
          cursorColor: textColor,
          decoration: InputDecoration(
            labelText: 'costPrice'.tr,
            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.75)),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondaryColor.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondaryColor,
                width: 1.4,
              ),
            ),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (value) => rawCostPrice = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: textColor.withValues(alpha: 0.75)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final raw = rawCostPrice.trim().replaceAll(',', '.');
              final parsed = raw.isEmpty ? 0.0 : double.tryParse(raw);
              if (parsed == null || parsed < 0) {
                Get.snackbar(
                  'error'.tr,
                  'invalidCostPrice'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.redColor,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              await controller.updateProductCostPrice(
                productId: product.productId,
                costPrice: parsed,
              );
            },
            child: Text(
              'save'.tr,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductLongPressActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userType == 'admin')
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text('costPrice'.tr),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCostPriceDialog(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('storeSection'.tr),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.showLocationActionSheetForProduct(
                  context,
                  product,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.secondaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
          height: 1.2,
        );

    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      productCode: product.productCode,
    );
    return Obx(() {
      final tab = controller.currentTab.value;
      final canSelectLocation = !isCloseouts && (tab == 0 || tab == 3);
      final deleteSelection = !isCloseouts &&
          controller.deleteSelectionActive.value &&
          controller.canDeleteProducts;
      final inGroupA = canSelectLocation &&
          controller.isProductInSwapGroupA(product.productId);
      final inGroupB = canSelectLocation &&
          controller.isProductInSwapGroupB(product.productId);
      final isSelected = deleteSelection
          ? controller.selectedProductIds.contains(product.productId)
          : inGroupA || inGroupB;
      final selectionColor = deleteSelection
          ? Colors.red
          : inGroupB
              ? AppColors.customOrange3
              : AppColors.operationalPurple;
      final canZoom = product.allImageUrlsInPriority.isNotEmpty;

      Future<void> handleCardTap() async {
        if (isCloseouts) {
          await controller.getProductDetails(productId: product.productId);
          controller.closeoutsProductsId = product.productId;

          controller.closeoutsProductNameController.text =
              controller.productDetails.value!.nameAr.toString();
          if (newComposition != null) {
            newComposition!.priceController.text =
                controller.productDetails.value!.normailPrice.toString();

            newComposition!.productIdController.text = product.productId;

            newComposition!.productNameController.text =
                controller.productDetails.value!.nameAr;
            controller.calculateGrandTotal();
          }
          productIdController!.text = product.productId;
          productNameController!.text =
              controller.productDetails.value!.nameAr.toString();

          Get.back();
          controller.update();
          return;
        }

        if (deleteSelection) {
          controller.toggleProductSelection(product.productId);
          return;
        }
        if (canSelectLocation && controller.locationSelectionActive.value) {
          controller.toggleProductSelection(product.productId);
          return;
        }
        await _openProductDetails();
      }

      bool isZoomTap(Offset localPosition) {
        if (!canZoom) return false;
        final edge = 28.w;
        return localPosition.dx <= edge && localPosition.dy <= edge;
      }

      return GestureDetector(
        onTapUp: (details) async {
          if (isZoomTap(details.localPosition)) {
            openProductImageViewer(context, product.preferredImageUrl);
            return;
          }
          await handleCardTap();
        },
        onLongPress: () async {
          if (isCloseouts) return;
          if (tab == 1) {
            Get.dialog(
              Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'moveToArchive'.tr,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.secondaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 20.sp,
                            ),
                      ),
                      SizedBox(height: 10.h),
                      AppButton(
                        isSafeArea: false,
                        isLoading: controller.isLoading,
                        text: 'apply'.tr,
                        onPressed: () {
                          controller.moveProductToArchive(
                            context: context,
                            productId: product.closeoutId.toString(),
                            isMove: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (canSelectLocation) {
            if (controller.locationSelectionActive.value) {
              controller.toggleProductSelection(product.productId);
              return;
            }
            if (userType == 'admin') {
              await _showProductLongPressActions(context);
            } else {
              await controller.showLocationActionSheetForProduct(
                context,
                product,
              );
            }
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: StockProductGridLayout.minCardHeight.h,
          ),
          child: Stack(
            children: [
              Material(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? selectionColor
                          : Colors.grey.withValues(alpha: 0.28),
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildProductImage(
                          context,
                          locationCodeLabel: locationCodeLabel,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 3.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return ClipRect(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: constraints.maxWidth,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                product.name,
                                                style: nameStyle,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 2.h),
                                              _buildStockLine(context),
                                              if (userType == 'admin' &&
                                                  tab == 0) ...[
                                                SizedBox(height: 1.h),
                                                _buildCostPriceLine(context),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: selectionColor,
                        width: 2.5,
                      ),
                      color: selectionColor.withValues(alpha: 0.12),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Container(
                          width: deleteSelection ? 24.w : null,
                          height: deleteSelection ? 24.w : null,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            horizontal: deleteSelection ? 0 : 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: selectionColor,
                            shape: deleteSelection
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: deleteSelection
                                ? null
                                : BorderRadius.circular(6.r),
                          ),
                          child: deleteSelection
                              ? Icon(
                                  Icons.delete_outline,
                                  size: 15.sp,
                                  color: Colors.white,
                                )
                              : Text(
                                  inGroupB ? 'B' : 'A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStockLine(BuildContext context) {
    if (controller.currentTab.value == 2) {
      return _InfoPill(
        icon: Icons.build_outlined,
        text: '${'numberOfProductsUsed'.tr} : ${product.numberOfUsedProducts}',
      );
    }
    if (controller.currentTab.value == 1) {
      return _InfoPill(
        icon: Icons.sell_outlined,
        text: '${'minimumSale'.tr} : ${product.productMinSalePrice}',
      );
    }
    return _InfoPill(
      icon: Icons.sell_outlined,
      text: '${'instantSaleRetailPriceLabel'.tr} : ${_formatRetailPrice()}',
    );
  }

  Widget _buildCostPriceLine(BuildContext context) {
    return _InfoPill(
      icon: Icons.payments_outlined,
      text: '${'costPrice'.tr} : ${_formatCostPrice()}',
    );
  }

  String _formatRetailPrice() {
    final value = product.normailPrice;
    if (value <= 0) return '-';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Widget _buildProductImage(
    BuildContext context, {
    String? locationCodeLabel,
  }) {
    final canZoom = product.allImageUrlsInPriority.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        ProductPriorityImage(
          imageUrls: product.allImageUrlsInPriority,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10.r),
          ),
          placeholder: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          missingPlaceholder: Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: Image.asset(
              AssetsManager.stockImage,
              fit: BoxFit.contain,
              width: 28.w,
              height: 28.w,
            ),
          ),
        ),
        if (locationCodeLabel != null)
          Positioned(
            top: 3.h,
            left: canZoom ? 24.w : 3.w,
            right: 3.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                locationCodeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 3.h,
          right: 3.w,
          child: _ImageBadge(
            text: _imageBadgeText(),
            icon: _imageBadgeIcon(),
          ),
        ),
        if (canZoom)
          Positioned(
            top: 3.h,
            left: 3.w,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Icon(
                Icons.zoom_in,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  String _imageBadgeText() {
    if (controller.currentTab.value == 2) {
      return product.numberOfUsedProducts;
    }
    if (controller.currentTab.value == 1) {
      return product.productMinSalePrice;
    }
    return product.stock;
  }

  IconData _imageBadgeIcon() {
    if (controller.currentTab.value == 2) {
      return Icons.build_outlined;
    }
    if (controller.currentTab.value == 1) {
      return Icons.sell_outlined;
    }
    return Icons.inventory_2_outlined;
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 19.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 9.sp,
            color: ThemeService.isDark.value
                ? Colors.white.withValues(alpha: 0.82)
                : AppColors.secondaryColor.withValues(alpha: 0.78),
          ),
          SizedBox(width: 2.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ThemeService.isDark.value
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.secondaryColor.withValues(alpha: 0.88),
                fontSize: 7.5.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8.sp, color: Colors.white),
          SizedBox(width: 2.w),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
