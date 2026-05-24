import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import 'instant_sale_cart_sheet.dart';
import 'instant_sale_cart_table.dart';

class AddNewInstantSaleWidget extends GetView<SalesController> {
  const AddNewInstantSaleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.cartRevision.value;
      final __ = controller.selectedPackageId.value;
      final hasItems =
          controller.hasSelectedPackage || controller.cartLines.isNotEmpty;

      if (!hasItems) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'items'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: 'instantSaleCart'.tr,
                onPressed: () => showInstantSaleCartSheet(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    if (controller.pickerSelectionCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: controller.hasSelectedPackage &&
                                    controller.cartLines.isEmpty
                                ? const Color(0xFFE65100)
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${controller.pickerSelectionCount}',
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
            ],
          ),
          SizedBox(height: 4.h),
          const InstantSaleCartTable(editablePackageQty: true),
        ],
      );
    });
  }
}
