import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_qty_stepper.dart';

/// صف الباكيج في السلة / جدول الأصناف (لون برتقالي + شارة بكيج).
class InstantSalePackageCartRow extends StatelessWidget {
  const InstantSalePackageCartRow({
    Key? key,
    required this.editable,
    this.compact = false,
    this.onRemoved,
  }) : super(key: key);

  final bool editable;
  final bool compact;
  final VoidCallback? onRemoved;

  static const Color _accent = Color(0xFFE65100);
  static const Color _bg = Color(0xFFFFF3E0);
  static const Color _border = Color(0xFFFFCC80);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();

    return Obx(() {
      final _ = controller.cartRevision.value;
      final __ = controller.selectedPackageId.value;
      final pkg = controller.selectedOfferPackage;
      if (!controller.hasSelectedPackage || pkg == null) {
        return const SizedBox.shrink();
      }

      final qty = int.tryParse(
            controller.items.first.quantityController.text.trim(),
          ) ??
          1;
      final unitPrice = pkg.price;
      final lineTotal = controller.packageLineTotal.value;
      final url = ShowNetImage.getThumbnailPhoto(pkg.image);
      final hasImage = url.isNotEmpty && pkg.image != 'no image';

      if (compact) {
        return _compactTableRow(
          context,
          controller: controller,
          pkgName: pkg.name,
          qty: qty,
          unitPrice: unitPrice,
          lineTotal: lineTotal,
          hasImage: hasImage,
          imageUrl: url,
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: editable ? 3.h : 0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _thumb(hasImage, url),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _packageBadge(),
                        SizedBox(height: 2.h),
                        Text(
                          pkg.name,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (editable && onRemoved != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24.w, minHeight: 24.w),
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemoved,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16.sp,
                        color: Colors.red.shade600,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  if (editable) ...[
                    Flexible(
                      fit: FlexFit.loose,
                      child: InstantSaleQtyStepper(
                        compact: true,
                        quantity: qty,
                        canDecrement: true,
                        canIncrement: qty < pkg.maxSellableQuantity,
                        onDecrement: () =>
                            controller.adjustPackagePickerQuantity(-1),
                        onIncrement: () =>
                            controller.adjustPackagePickerQuantity(1),
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ] else ...[
                    Expanded(
                      child: Text(
                        '${'quantity'.tr}: $qty',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      '${'price'.tr}: ${SalesAmountFormat.display(unitPrice)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'total'.tr,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        SalesAmountFormat.display(lineTotal),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _compactTableRow(
    BuildContext context, {
    required SalesController controller,
    required String pkgName,
    required int qty,
    required double unitPrice,
    required double lineTotal,
    required bool hasImage,
    required String imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _thumb(hasImage, imageUrl),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _packageBadge(),
                      Text(
                        pkgName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: editable
                ? Center(
                    child: InstantSaleQtyStepper(
                      compact: true,
                      quantity: qty,
                      canDecrement: qty > 0,
                      canIncrement: true,
                      onDecrement: () =>
                          controller.adjustPackagePickerQuantity(-1),
                      onIncrement: () =>
                          controller.adjustPackagePickerQuantity(1),
                    ),
                  )
                : Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.sp),
                  ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              SalesAmountFormat.display(unitPrice),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              SalesAmountFormat.display(lineTotal),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        'instantSalePackageBadge'.tr,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _thumb(bool hasImage, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.r),
      child: SizedBox(
        width: 32.w,
        height: 32.w,
        child: hasImage
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : ColoredBox(
                color: const Color(0xFFFFE0B2),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  size: 18.sp,
                  color: _accent,
                ),
              ),
      ),
    );
  }
}
