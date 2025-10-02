import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/get_shown_boxes_model.dart';
import '../controllers/boxes_controller.dart';
import 'add_balance_widget.dart';
import 'transfer_balance_widget.dart';

class OnLongPressInBox extends GetView<BoxesController> {
  const OnLongPressInBox({Key? key, required this.box}) : super(key: key);

  final GetShownBoxesModel box;
  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor:
          ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
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
                if (controller.currentTab.value == 0)
                  TextButton.icon(
                    onPressed: () {
                      controller.addBalanceValueController.clear();
                      Get.back();
                      Get.dialog(AddBalanceWidget(boxId: box.boxId));
                    },
                    label: Text(
                      'addOrWithdrawBalance'.tr,
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
                if (controller.currentTab.value == 0) SizedBox(height: 10.h),
                if (controller.currentTab.value == 0)
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.transferToBoxIdController.clear();
                      controller.transferTotalController.clear();
                      Get.dialog(
                        TransferBalanceWidget(
                          boxId: box.boxId,
                          currency: box.currency,
                        ),
                      );
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
                if (controller.currentTab.value == 2)
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.dialog(
                        Dialog(
                          backgroundColor: ThemeService.isDark.value
                              ? AppColors.darkColor
                              : AppColors.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(15.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${'deleteBox'.tr} ${box.boxName}',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        style: textStyle.copyWith(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.redColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        isSafeArea: false,
                                        isLoading: controller.isAddBoxLoading,
                                        text: 'yes',
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(30.r),
                                        onPressed: () {
                                          controller.editBox(
                                            context: context,
                                            boxId: box.boxId.toString(),
                                            isDelete: true,
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: AppButton(
                                        isSafeArea: false,
                                        isLoading: controller.isAddBoxLoading,
                                        text: 'cancel',
                                        textColor: Colors.red,
                                        color: Colors.transparent,
                                        borderColor: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(30.r),
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
                    label: Text(
                      'deleteBox'.tr,
                      style: textStyle.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.redColor,
                      ),
                    ),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 25.h,
                      color: AppColors.redColor,
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
