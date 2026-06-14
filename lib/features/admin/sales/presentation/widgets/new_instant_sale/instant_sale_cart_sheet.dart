import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_package_cart_row.dart';
import 'instant_sale_qty_stepper.dart';

Future<void> showInstantSaleCartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _InstantSaleCartSheet(),
  );
}

class _InstantSaleCartSheet extends StatelessWidget {
  const _InstantSaleCartSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final isDark = ThemeService.isDark.value;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.65.sh),
          margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor4 : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () {
                          final _ = controller.selectedPackageId.value;
                          return Text(
                          '${'instantSaleCart'.tr} (${controller.pickerSelectionCount})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        );
                        },
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 28.w,
                        minHeight: 28.w,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 18.sp),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Flexible(
                child: Obx(() {
                  final _ = controller.cartRevision.value;
                  final __ = controller.selectedPackageId.value;
                  final hasPackage = controller.hasSelectedPackage;
                  final lines = controller.cartLines;

                  if (!hasPackage && lines.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'instantSaleCartEmpty'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    children: [
                      if (hasPackage)
                        InstantSalePackageCartRow(
                          editable: true,
                          onRemoved: () {
                            final pkg = controller.selectedOfferPackage;
                            if (pkg != null) {
                              controller.togglePackageForPicker(pkg);
                            }
                            if (!controller.hasSelectedPackage &&
                                controller.cartLines.isEmpty) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      if (hasPackage && lines.isNotEmpty)
                        Divider(height: 8.h, color: Colors.grey.shade300),
                      ...List.generate(lines.length, (index) {
                        final line = lines[index];
                        if (line.isDisposed) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            if (index > 0)
                              Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                            _CartLineEditor(
                              line: line,
                              index: index,
                              lineTotal: line.lineTotal.value,
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('close'.tr, style: TextStyle(fontSize: 13.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLineEditor extends StatelessWidget {
  const _CartLineEditor({
    required this.line,
    required this.index,
    required this.lineTotal,
  });

  final InstantSaleCartLine line;
  final int index;
  final double lineTotal;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final url = ShowNetImage.getThumbnailPhoto(line.imageUrl);
    final hasImage = url.isNotEmpty && line.imageUrl != 'no image';
    if (line.isDisposed) return const SizedBox.shrink();

    final qty = int.tryParse(line.quantityText) ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: hasImage
                      ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  line.displayName,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24.w, minHeight: 24.w),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  controller.removeCartLine(index);
                  if (!controller.hasSelectedPackage &&
                      controller.cartLines.isEmpty) {
                    Navigator.pop(context);
                  }
                },
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
              Flexible(
                fit: FlexFit.loose,
                child: InstantSaleQtyStepper(
                  compact: true,
                  quantity: qty,
                  canDecrement: qty > 0,
                  canIncrement: true,
                  onDecrement: () =>
                      controller.adjustCartLineQuantity(index, -1),
                  onIncrement: () =>
                      controller.adjustCartLineQuantity(index, 1),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _CompactNumberField(
                  label: 'price'.tr,
                  controller: line.priceController,
                  onChanged: (_) {
                    line.recalculateTotal();
                    controller.calculateGrandTotal();
                    controller.bumpCartRevision();
                  },
                ),
              ),
              SizedBox(width: 6.w),
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
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 28.h,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: TextStyle(fontSize: 11.sp),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
