import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import 'package:doctorbike/features/admin/stock/data/models/offer_package_model.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_package_detail_sheet.dart';
import 'instant_sale_qty_stepper.dart';

class InstantSalePackageCard extends StatelessWidget {
  const InstantSalePackageCard({Key? key, required this.package}) : super(key: key);

  final OfferPackageModel package;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final url = ShowNetImage.getThumbnailPhoto(package.image);
    final hasImage = url.isNotEmpty && package.image != 'no image';
    final maxQty = package.maxSellableQuantity;
    final unavailable = maxQty < 1;

    return Obx(() {
      final selected = controller.isPackageSale.value &&
          controller.selectedPackageId.value == package.id;
      final qty = selected
          ? int.tryParse(
                controller.items.first.quantityController.text.trim(),
              ) ??
              1
          : 0;

      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFFE65100)
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10.r),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF3E0),
                      Colors.white,
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: unavailable
                      ? null
                      : () => controller.togglePackageForPicker(package),
                  onLongPress: () =>
                      showInstantSalePackageDetailSheet(context, package),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: const Color(0xFFFFF8E1),
                              child: Icon(
                                Icons.card_giftcard_rounded,
                                size: 26.sp,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                      Positioned(
                        top: 3.h,
                        right: 3.w,
                        child: const _PackageBadge(),
                      ),
                      Positioned(
                        bottom: 3.h,
                        right: 3.w,
                        child: _MaxBadge(max: maxQty),
                      ),
                      if (selected)
                        Positioned(
                          top: 3.h,
                          left: 3.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
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
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: unavailable
                          ? null
                          : () => controller.togglePackageForPicker(package),
                      onLongPress: () => showInstantSalePackageDetailSheet(
                        context,
                        package,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            package.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: unavailable
                                  ? Colors.grey.shade500
                                  : const Color(0xFFBF360C),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            SalesAmountFormat.displayShekel(package.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: unavailable
                                  ? Colors.grey.shade500
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Center(
                      child: InstantSaleQtyStepper(
                        compact: true,
                        quantity: qty,
                        canDecrement: selected && qty > 0,
                        canIncrement: selected && qty < maxQty,
                        onDecrement: selected
                            ? () => controller.adjustPackagePickerQuantity(-1)
                            : null,
                        onIncrement: selected
                            ? () => controller.adjustPackagePickerQuantity(1)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer, size: 8.sp, color: Colors.white),
          SizedBox(width: 2.w),
          Text(
            'instantSalePackageBadge'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  const _MaxBadge({required this.max});

  final int max;

  @override
  Widget build(BuildContext context) {
    final out = max < 1;
    final low = !out && max <= 3;
    final bg = out
        ? Colors.red.shade700
        : low
            ? Colors.orange.shade700
            : Colors.black.withValues(alpha: 0.65);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, size: 8.sp, color: Colors.white),
          SizedBox(width: 2.w),
          Text(
            '$max',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
