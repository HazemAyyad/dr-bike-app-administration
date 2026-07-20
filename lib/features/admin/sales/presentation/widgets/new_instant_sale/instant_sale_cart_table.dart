import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/product_image_utils.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/utils/sale_variant_display.dart';
import '../../controllers/sales_controller.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_cart_line_sheet.dart';
import 'instant_sale_package_cart_row.dart';
import 'instant_sale_price_history_sheet.dart';

/// ملخص أصناف السلة (باكيج + منتجات) — جدول أفقي مع مقاس/لون.
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
      final selectedPackageMarker = controller.selectedPackageId.value;
      selectedPackageMarker;
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
      final headerBg =
          isDark ? AppColors.customGreyColor : const Color(0xFFEEF4FF);

      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            if (hasPackage)
              InstantSalePackageCartRow(
                compact: true,
                editable: editablePackageQty,
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width - 32.w,
                ),
                child: Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius: hasPackage
                            ? null
                            : BorderRadius.vertical(top: Radius.circular(7.r)),
                      ),
                      child: Row(
                        children: [
                          _headerCell('item', 150),
                          _headerCell('size', 72),
                          _headerCell('color', 72),
                          _headerCell('quantity', 56),
                          _headerCell('price', 108),
                          _headerCell('total', 72),
                          SizedBox(width: 34.w),
                        ],
                      ),
                    ),
                    ...List.generate(productLines.length, (index) {
                      final line = productLines[index];
                      if (line.isDisposed) return const SizedBox.shrink();
                      final qty = line.quantityText;
                      final total = line.lineTotal.value;
                      final isLast = index == productLines.length - 1;

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.customGreyColor4
                              : Colors.white,
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150.w,
                              child: Row(
                                children: [
                                  _thumb(context, line.imageUrl),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => showInstantSaleCartLineSheet(
                                        context,
                                        line,
                                      ),
                                      child: Text(
                                        line.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          color: AppColors.primaryColor,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors
                                              .primaryColor
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _dataCell(
                              variantDashOrValue(line.sizeLabel),
                              72,
                            ),
                            _dataCell(
                              variantDashOrValue(line.colorLabel),
                              72,
                            ),
                            _dataCell(
                              qty.isEmpty ? '—' : qty,
                              56,
                              center: true,
                            ),
                            SizedBox(
                              width: 108.w,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _PriceField(
                                      line: line,
                                      onChanged: () {
                                        line.recalculateTotal();
                                        controller.calculateGrandTotal();
                                        controller.syncCartToItems();
                                        controller.bumpCartRevision();
                                      },
                                    ),
                                  ),
                                  InstantSalePriceHistoryButton(
                                    line: line,
                                    cartLineIndex: index,
                                    compact: true,
                                    allowApply: true,
                                  ),
                                ],
                              ),
                            ),
                            _dataCell(
                              SalesAmountFormat.display(total),
                              72,
                              center: true,
                              bold: true,
                            ),
                            SizedBox(
                              width: 34.w,
                              child: IconButton(
                                tooltip: 'delete'.tr,
                                padding: EdgeInsets.zero,
                                constraints:
                                    BoxConstraints.tight(Size(28.w, 28.w)),
                                icon: Icon(
                                  Icons.close,
                                  size: 17.sp,
                                  color: Colors.red.shade600,
                                ),
                                onPressed: () async {
                                  final confirmed =
                                      await _confirmRemoveLine(context, line);
                                  if (confirmed != true) return;

                                  controller.removeCartLine(index);
                                  controller.syncCartToItems();
                                  if (!controller.hasSelectedPackage &&
                                      controller.cartLines.isEmpty) {
                                    Get.offNamed(
                                      controller.isAdjustmentInstantSale
                                          ? AppRoutes
                                              .ADJUSTMENTSALEPRODUCTPICKER
                                          : AppRoutes.INSTANTSALEPRODUCTPICKER,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<bool?> _confirmRemoveLine(
    BuildContext context,
    InstantSaleCartLine line,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'confirmDelete'.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            '${'delete'.tr}: ${line.displayName}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'cancel'.tr,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );
  }

  Widget _headerCell(String key, double width) {
    return SizedBox(
      width: width.w,
      child: Text(
        key.tr,
        textAlign: TextAlign.center,
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

  Widget _dataCell(
    String value,
    double width, {
    bool center = false,
    bool bold = false,
  }) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: bold ? AppColors.primaryColor : null,
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context, String imageUrl) {
    final url = ShowNetImage.getThumbnailPhoto(imageUrl);
    final ok = ProductImageUtils.isValidUrl(imageUrl);

    return GestureDetector(
      onTap: ok ? () => openProductImageViewer(context, imageUrl) : null,
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

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.line,
    required this.onChanged,
  });

  final InstantSaleCartLine line;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (line.isDisposed) return const SizedBox.shrink();

    return SizedBox(
      height: 32.h,
      child: TextField(
        controller: line.priceController,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
