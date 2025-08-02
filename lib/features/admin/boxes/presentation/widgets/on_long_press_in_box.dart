import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';
import 'add_balance_widget.dart';
import 'transfer_balance_widget.dart';

class OnLongPressInBox extends GetView<BoxesController> {
  const OnLongPressInBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor:
          ThemeService.isDark.value ? AppColors.darckColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(5.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.dialog(AddBalanceWidget(controller: controller));
                  },
                  label: Text(
                    'addBalance'.tr,
                    style: textStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icon(
                    Icons.add,
                    size: 25.h,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.dialog(TransferBalanceWidget(controller: controller));
                  },
                  label: Text(
                    'transferBalance'.tr,
                    style: textStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icon(
                    Icons.swap_horiz,
                    size: 25.h,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
