import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/stock_controller.dart';
import '../views/product_stock_movements_screen.dart';
import 'stock_variant_adjust_sheet.dart';
import '../utils/open_product_purchase.dart';

/// Entry row on product details → dedicated stock movements page.
class ProductStockMovementsLink extends StatelessWidget {
  const ProductStockMovementsLink({
    Key? key,
    required this.productId,
    required this.productName,
    required this.currentStock,
    this.hasVariants = false,
  }) : super(key: key);

  final String productId;
  final String productName;
  final int currentStock;
  final bool hasVariants;

  StockController get _stock => Get.find<StockController>();

  void _openMovements() {
    Get.toNamed(
      AppRoutes.PRODUCTSTOCKMOVEMENTSSCREEN,
      arguments: ProductStockMovementsArgs(
        productId: productId,
        productName: productName,
        currentStock: currentStock,
        hasVariants: hasVariants,
      ),
    );
  }

  Future<void> _openPurchase(BuildContext context) async {
    String? sizeColorId;
    if (hasVariants) {
      var product = _stock.productDetails.value;
      if (product == null || product.id != productId) {
        await _stock.getProductDetails(productId: productId);
        product = _stock.productDetails.value;
      }
      if (product == null || !context.mounted) return;
      final target = await showStockVariantAdjustSheet(
        context: context,
        product: product,
      );
      if (target == null || !context.mounted) return;
      sizeColorId = target.sizeColorId;
    }
    if (!context.mounted) return;
    await openProductPurchase(
      context: context,
      productId: productId,
      sizeColorId: sizeColorId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: AdminUiColors.cardBackground(context),
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            if (canPurchaseProductFromStock)
              IconButton(
                tooltip: 'addStockQuick'.tr,
                onPressed: () => _openPurchase(context),
                icon: Icon(
                  Icons.add_shopping_cart_outlined,
                  size: 24.sp,
                  color: cs.primary,
                ),
              ),
            Expanded(
              child: InkWell(
                onTap: _openMovements,
                borderRadius: BorderRadius.circular(12.r),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 22.sp,
                      color: cs.primary,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'stockMovements'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'stockMovementsPageHint'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AdminUiColors.subtleOverlay(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$currentStock',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_left,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
