import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/product_image_utils.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceProductsSection extends StatelessWidget {
  const MaintenanceProductsSection({Key? key, required this.controller})
      : super(key: key);

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isLocked =
            controller.selectedStep.value >= 4 || controller.isDelivered.value;

        return Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'maintenanceParts'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  if (!isLocked)
                    TextButton.icon(
                      onPressed: () => controller.openProductPicker(context),
                      icon: Icon(Icons.add, size: 18.sp),
                      label: Text('add'.tr, style: TextStyle(fontSize: 12.sp)),
                    ),
                ],
              ),
              if (controller.maintenanceProducts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Text(
                    'maintenanceNoPartsYet'.tr,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              else
                _ProductsTable(controller: controller),
              SizedBox(height: 8.h),
              _amountField(
                label: 'maintenanceLaborCost'.tr,
                controller: controller.laborCostController,
                enabled: !isLocked,
                onChanged: () {
                  controller.recalculateTotals();
                  controller.scheduleAutoSave();
                },
              ),
              SizedBox(height: 6.h),
              _amountField(
                label: 'discount'.tr,
                controller: controller.discountController,
                enabled: !isLocked,
                onChanged: () {
                  controller.recalculateTotals();
                  controller.scheduleAutoSave();
                },
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    SalesAmountFormat.display(controller.invoiceTotal),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _amountField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required VoidCallback onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    final isLocked =
        controller.selectedStep.value >= 4 || controller.isDelivered.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.r)),
            ),
            child: Row(
              children: [
                Expanded(child: _headerText('productName'.tr)),
                _headerCell('quantity'.tr, 34),
                _headerCell('price'.tr, 58),
                _headerCell('total'.tr, 62),
                if (!isLocked) SizedBox(width: 26.w),
              ],
            ),
          ),
          ...List.generate(controller.maintenanceProducts.length, (index) {
            final item = controller.maintenanceProducts[index];
            final isLast = index == controller.maintenanceProducts.length - 1;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _ProductThumb(imageUrl: item.imageUrl),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            item.productName.isEmpty ? '-' : item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _dataCell('${item.quantity}', 34, center: true),
                  _dataCell(
                    SalesAmountFormat.display(item.unitPrice),
                    58,
                    center: true,
                  ),
                  _dataCell(
                    SalesAmountFormat.display(item.lineTotal),
                    62,
                    center: true,
                    bold: true,
                  ),
                  if (!isLocked)
                    SizedBox(
                      width: 26.w,
                      child: IconButton(
                        tooltip: 'delete'.tr,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tight(
                          Size(24.w, 24.w),
                        ),
                        icon: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: Colors.red.shade500,
                        ),
                        onPressed: () => controller.removeProduct(index),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _headerCell(String value, double width) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: bold ? AppColors.primaryColor : Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final thumbnail = ShowNetImage.getThumbnailPhoto(imageUrl);
    final hasImage = ProductImageUtils.isValidUrl(imageUrl);

    return GestureDetector(
      onTap: hasImage ? () => openProductImageViewer(context, imageUrl) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.r),
        child: SizedBox(
          width: 30.w,
          height: 30.w,
          child: hasImage
              ? CachedNetworkImage(imageUrl: thumbnail, fit: BoxFit.cover)
              : ColoredBox(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 15.sp,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
    );
  }
}
