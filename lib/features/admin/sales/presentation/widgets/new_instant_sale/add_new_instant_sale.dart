import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import 'instant_sale_add_product_modal.dart';
import 'instant_sale_cart_table.dart';
import 'offer_package_sale_widget.dart';

class AddNewInstantSaleWidget extends GetView<SalesController> {
  const AddNewInstantSaleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OfferPackageSaleWidget(),
        SizedBox(height: 8.h),
        Obx(
          () => controller.isPackageSale.value
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'items'.tr,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: () =>
                                showInstantSaleAddProductModal(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    'instantSaleAddProduct'.tr,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    const InstantSaleCartTable(),
                  ],
                ),
        ),
      ],
    );
  }
}
