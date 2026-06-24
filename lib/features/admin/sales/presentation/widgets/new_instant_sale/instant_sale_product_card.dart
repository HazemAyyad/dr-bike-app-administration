import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../stock/presentation/widgets/product_location_badge.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../../sales_orders/presentation/utils/sales_order_stock_context.dart';
import '../../controllers/sales_controller.dart';
import 'instant_sale_product_detail_sheet.dart';
import 'instant_sale_qty_stepper.dart';

class InstantSaleProductCard extends StatelessWidget {
  const InstantSaleProductCard({
    Key? key,
    required this.product,
    this.showOrderStock = false,
  }) : super(key: key);

  final ProductModel product;
  final bool showOrderStock;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final url = ShowNetImage.getThumbnailPhoto(product.imageUrl);
    final hasImage = url.isNotEmpty && product.imageUrl != 'no image';
    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      productCode: product.displayProductCode,
    );

    return Obx(() {
      final _ = controller.cartRevision.value;
      final __ = controller.pickerBuyerIdRx.value;
      final ___ = controller.pickerSellerIdRx.value;
      final ____ = controller.pickerPartnerIsCustomer.value;
      final pickerStockEnabled = controller.pickerReservedStockEnabled.value;
      final stockUiActive = showOrderStock ||
          pickerStockEnabled ||
          SalesOrderStockContext.isActive;
      final ordersCtrl = stockUiActive ? _resolveOrdersController() : null;
      if (ordersCtrl != null) {
        // يحدّث البطاقة بعد جلب بيانات المحجوز من السيرفر.
        final _ = ordersCtrl.stockAvailabilityVersion.value;
        final productId = int.tryParse(product.id);
        if (productId != null) {
          final __ = ordersCtrl.productStockAvailability['$productId'];
          ordersCtrl.requestStockAvailabilityIfMissing(productId);
        }
      }
      final orderStock =
          ordersCtrl?.availabilityForProduct(product.id);
      final physicalStock = orderStock?.physicalStock ??
          int.tryParse(product.stock) ??
          0;
      final displayStock = orderStock?.availableQty ?? physicalStock;
      final badgeReserved = orderStock?.totalReservedQty ??
          orderStock?.reservedQty ??
          0;
      final effectiveReserved = badgeReserved > 0
          ? badgeReserved
          : (physicalStock - displayStock).clamp(0, physicalStock);
      final outOfStock = physicalStock < 1;
      final qty = controller.cartQtyForProduct(product.id);
      final inCart = qty > 0;
      final simpleLineIdx = controller.cartLines.indexWhere(
        (l) =>
            l.productId == product.id &&
            !l.isDisposed &&
            (l.sizeColorId == null || l.sizeColorId!.isEmpty),
      );
      final linePrice = simpleLineIdx >= 0
          ? controller.cartLines[simpleLineIdx].priceText
          : null;
      final priceLabel = controller.displayPriceLabelForProduct(
        product,
        cartLinePrice: linePrice,
      );

      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: inCart
                  ? AppColors.primaryColor
                  : Colors.grey.shade300,
              width: inCart ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: outOfStock
                      ? null
                      : () => controller.toggleProductInCart(
                            product,
                            context: context,
                          ),
                  onLongPress: () =>
                      showInstantSaleProductDetailSheet(context, product),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 22.sp,
                                color: Colors.grey.shade400,
                              ),
                            ),
                      Positioned(
                        bottom: 3.h,
                        right: 3.w,
                        child: _StockBadge(
                          displayStock: displayStock,
                          physicalStock: physicalStock,
                          reservedStock: effectiveReserved,
                        ),
                      ),
                      if (locationCodeLabel != null)
                        Positioned(
                          top: 3.h,
                          left: 3.w,
                          right: 3.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 2.h,
                            ),
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
                      if (inCart)
                        Positioned(
                          top: locationCodeLabel != null ? 18.h : 3.h,
                          left: 3.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: outOfStock
                              ? null
                              : () => controller.toggleProductInCart(
                                    product,
                                    context: context,
                                  ),
                          onLongPress: () => showInstantSaleProductDetailSheet(
                            context,
                            product,
                          ),
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
                                          product.nameAr,
                                          maxLines: 2,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w600,
                                            height: 1.05,
                                          ),
                                        ),
                                        Text(
                                          priceLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 7.sp,
                                            color: outOfStock
                                                ? Colors.grey.shade500
                                                : AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            height: 1.05,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20.h,
                        child: Center(
                          child: InstantSaleQtyStepper(
                            compact: true,
                            quantity: qty,
                            canDecrement: inCart,
                            canIncrement: physicalStock > 0,
                            onQuantityTap: product.hasVariants
                                ? null
                                : () => controller.promptProductQuantity(
                                      context,
                                      product,
                                    ),
                            onDecrement: inCart
                                ? () => controller.decrementProductInCart(
                                      product.id,
                                    )
                                : null,
                            onIncrement: physicalStock > 0
                                ? () => controller.incrementProductInCart(
                                      product,
                                      context: context,
                                    )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  static SalesOrdersController? _resolveOrdersController() {
    if (!Get.isRegistered<SalesOrdersController>() &&
        !Get.isPrepared<SalesOrdersController>()) {
      return null;
    }
    return Get.find<SalesOrdersController>();
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.displayStock,
    required this.physicalStock,
    required this.reservedStock,
  });

  final int displayStock;
  final int physicalStock;
  final int reservedStock;

  @override
  Widget build(BuildContext context) {
    final out = physicalStock < 1;
    final hasReservation = reservedStock > 0 ||
        (physicalStock > displayStock && displayStock >= 0);
    final low = !out && displayStock <= 3;
    final bg = out
        ? Colors.red.shade700
        : hasReservation
            ? Colors.deepOrange.shade700
            : low
                ? Colors.orange.shade700
                : Colors.black.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasReservation ? Icons.lock_outline : Icons.inventory_2_outlined,
                size: 8.sp,
                color: Colors.white,
              ),
              SizedBox(width: 2.w),
              Text(
                hasReservation ? '$displayStock' : '$physicalStock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (hasReservation)
          Container(
            margin: EdgeInsets.only(top: 2.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.deepOrange.shade300, width: 0.8),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'salesOrderPickerReservedShort'.trParams({
                'reserved': '$reservedStock',
              }),
              style: TextStyle(
                color: Colors.deepOrange.shade900,
                fontSize: 6.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
