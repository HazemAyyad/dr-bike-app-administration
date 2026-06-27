import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../../data/models/maintenance_product_model.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceProductsSection extends StatelessWidget {
  const MaintenanceProductsSection({Key? key, required this.controller})
      : super(key: key);

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isLocked = controller.selectedStep.value >= 4 ||
            controller.isDelivered.value;

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
                ...controller.maintenanceProducts.map(_productTile),
              SizedBox(height: 8.h),
              _amountField(
                label: 'maintenanceLaborCost'.tr,
                controller: controller.laborCostController,
                enabled: !isLocked,
                onChanged: controller.recalculateTotals,
              ),
              SizedBox(height: 6.h),
              _amountField(
                label: 'discount'.tr,
                controller: controller.discountController,
                enabled: !isLocked,
                onChanged: controller.recalculateTotals,
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

  Widget _productTile(MaintenanceProductModel item) {
    final index = controller.maintenanceProducts.indexOf(item);
    final isLocked = controller.selectedStep.value >= 4 ||
        controller.isDelivered.value;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.quantity} × ${SalesAmountFormat.display(item.unitPrice)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(
            SalesAmountFormat.display(item.lineTotal),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          if (!isLocked)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, size: 18.sp, color: Colors.red.shade400),
              onPressed: () => controller.removeProduct(index),
            ),
        ],
      ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}
