import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/purchase_orders_controller.dart';

class CancelBill extends GetView<PurchaseOrdersController> {
  const CancelBill({Key? key, required this.billId}) : super(key: key);

  final int billId;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          width: 200.w,
          color: Colors.red,
          text: 'return_full_order',
          onPressed: () {
            Get.dialog(
              Dialog(
                backgroundColor: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'areYouSure'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redColor,
                            ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              isLoading: controller.isLoading2,
                              borderRadius: BorderRadius.circular(30.r),
                              isSafeArea: false,
                              color: AppColors.redColor,
                              text: 'yes'.tr,
                              onPressed: () {
                                controller.cancelBill(
                                  context: context,
                                  billId: billId.toString(),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: AppButton(
                              borderRadius: BorderRadius.circular(30.r),
                              borderColor: AppColors.redColor,
                              isSafeArea: false,
                              text: 'cancel'.tr,
                              textColor: AppColors.redColor,
                              color: Colors.transparent,
                              onPressed: () => Get.back(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 20.w),
      ],
    );
  }
}
