import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../controllers/stock_controller.dart';

int productOptionsActiveCount(StockController c) {
  var n = 0;
  if (c.isShowProduct.value) n++;
  if (c.isNewItemProduct.value) n++;
  if (c.isMoreSalesProduct.value) n++;
  if (c.isForcedSale.value) n++;
  return n;
}

Future<void> showProductOptionsPickerSheet() async {
  await Get.bottomSheet<void>(
    const _ProductOptionsPickerSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Product visibility / badges / forced sale — compact tile + bottom sheet.
class ProductOptionsPickerTile extends GetView<StockController> {
  const ProductOptionsPickerTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final count = productOptionsActiveCount(controller);
      return Material(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: showProductOptionsPickerSheet,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20.sp,
                  color: cs.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'sectionProductOptions'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        count == 0
                            ? 'selectProductOptionsHint'.tr
                            : 'productOptionsActiveCount'
                                .trParams({'count': count.toString()}),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                              fontSize: 11.sp,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  size: 22.sp,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ProductOptionsPickerSheet extends GetView<StockController> {
  const _ProductOptionsPickerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.55;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'sectionProductOptions'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Column(
                children: [
                  CustomCheckBox(
                    title: 'productVisible',
                    value: controller.isShowProduct,
                    onChanged: (value) {
                      controller.isShowProduct.value = value!;
                    },
                  ),
                  CustomCheckBox(
                    title: 'productNewBadge',
                    value: controller.isNewItemProduct,
                    onChanged: (value) {
                      controller.isNewItemProduct.value = value!;
                    },
                  ),
                  CustomCheckBox(
                    title: 'productBestSeller',
                    value: controller.isMoreSalesProduct,
                    onChanged: (value) {
                      controller.isMoreSalesProduct.value = value!;
                    },
                  ),
                  CustomCheckBox(
                    title: 'isForcedSale',
                    value: controller.isForcedSale,
                    onChanged: (value) {
                      controller.isForcedSale.value = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: Get.back,
                  child: Text('done'.tr),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
