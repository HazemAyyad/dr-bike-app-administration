import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_package_cart_row.dart';

/// ملخص أصناف السلة (باكيج + منتجات).
class InstantSaleCartTable extends GetView<SalesController> {
  const InstantSaleCartTable({
    Key? key,
    this.editablePackageQty = false,
  }) : super(key: key);

  final bool editablePackageQty;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.cartRevision.value;
      final __ = controller.selectedPackageId.value;
      final hasPackage = controller.hasSelectedPackage;
      final productLines = controller.cartLines;

      if (!hasPackage && productLines.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text(
            'instantSaleCartEmpty'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
          ),
        );
      }

      final isDark = ThemeService.isDark.value;
      final headerBg = isDark
          ? AppColors.customGreyColor
          : const Color(0xFFEEF4FF);

      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(7.r)),
              ),
              child: Row(
                children: [
                  _header('item', 4, start: true),
                  _header('quantity', 2),
                  _header('price', 2),
                  _header('total', 2),
                ],
              ),
            ),
            if (hasPackage)
              InstantSalePackageCartRow(
                compact: true,
                editable: editablePackageQty,
              ),
            ...List.generate(productLines.length, (index) {
              final line = productLines[index];
              if (line.isDisposed) return const SizedBox.shrink();
              final qty = line.quantityText;
              final price = line.priceText;
              final total = line.lineTotal.value;
              final isLast = index == productLines.length - 1;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.customGreyColor4 : Colors.white,
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          _thumb(context, line.imageUrl),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              line.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        qty.isEmpty ? '—' : qty,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        price.isEmpty
                            ? '—'
                            : SalesAmountFormat.display(
                                SalesAmountFormat.parse(price),
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        SalesAmountFormat.display(total),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _header(String key, int flex, {bool start = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        key.tr,
        textAlign: start ? TextAlign.start : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context, String imageUrl) {
    final url = ShowNetImage.getThumbnailPhoto(imageUrl);
    final ok = url.isNotEmpty && imageUrl != 'no image';

    return GestureDetector(
      onTap: () => openProductImageViewer(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: ok
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
              : ColoredBox(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 14.sp,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
    );
  }
}
