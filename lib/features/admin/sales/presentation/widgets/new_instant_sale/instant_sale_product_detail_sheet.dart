import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/initial_bindings.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../stock/presentation/widgets/product_location_badge.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/sales_controller.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_price_history_sheet.dart';

Future<void> showInstantSaleProductDetailSheet(
  BuildContext context,
  ProductModel product,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProductDetailSheet(product: product),
  );
}

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({required this.product});

  final ProductModel product;

  InstantSaleCartLine? _simpleCartLine(SalesController controller) {
    final idx = controller.cartLines.indexWhere(
      (l) =>
          l.productId == product.id &&
          !l.isDisposed &&
          (l.sizeColorId == null || l.sizeColorId!.isEmpty),
    );
    if (idx < 0) return null;
    return controller.cartLines[idx];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final url = ShowNetImage.getThumbnailPhoto(product.imageUrl);
    final hasImage = url.isNotEmpty && product.imageUrl != 'no image';
    final stock = int.tryParse(product.stock) ?? 0;
    final isAdmin = userType.toLowerCase() == 'admin';
    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      productCode: product.displayProductCode,
    );
    final cartLine = _simpleCartLine(controller);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Obx(() {
          controller.pickerBuyerIdRx.value;
          controller.pickerSellerIdRx.value;
          controller.pickerPartnerIsCustomer.value;
          final linePrice = cartLine?.priceText;
          final retail = product.unitPrice;
          final historyLine = cartLine ??
              InstantSaleCartLine.fromProduct(
                product,
                unitPrice: controller.displayPriceLabelForProduct(product),
              );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'instantSaleProductDetails'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              if (hasImage)
                GestureDetector(
                  onTap: () =>
                      openProductImageViewer(context, product.imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (hasImage) SizedBox(height: 12.h),
              Text(
                product.nameAr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (locationCodeLabel != null) ...[
                SizedBox(height: 6.h),
                _row('productCode'.tr, locationCodeLabel),
              ],
              SizedBox(height: 10.h),
              _row('stock'.tr, '$stock'),
              _row(
                'retailPrice'.tr,
                retail > 0
                    ? SalesAmountFormat.displayShekel(retail)
                    : 'instantSaleNoRetailPrice'.tr,
              ),
              if (isAdmin)
                _row(
                  'ThePurchase'.tr,
                  product.purchaseCost > 0
                      ? SalesAmountFormat.displayShekel(product.purchaseCost)
                      : '—',
                ),
              if (linePrice != null && linePrice.trim().isNotEmpty) ...[
                SizedBox(height: 4.h),
                _row(
                  'price'.tr,
                  SalesAmountFormat.display(
                    SalesAmountFormat.parse(linePrice),
                  ),
                ),
              ],
              SizedBox(height: 10.h),
              InstantSalePriceHistoryButton(
                line: historyLine,
                forceShow: true,
                allowApply: cartLine != null,
                cartLineIndex: cartLine != null
                    ? controller.cartLines.indexWhere(
                        (l) => identical(l, cartLine),
                      )
                    : null,
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('close'.tr, style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
