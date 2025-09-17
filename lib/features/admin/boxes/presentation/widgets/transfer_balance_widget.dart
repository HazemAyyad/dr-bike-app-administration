import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';

class TransferBalanceWidget extends GetView<BoxesController> {
  const TransferBalanceWidget({Key? key, required this.boxId})
      : super(key: key);

  final int boxId;
  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(15.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 25.h,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'transferBalance'.tr,
                    style: textStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              CustomDropdownField(
                label: 'to',
                hint: 'boxNameExample',
                dropdownField: controller.filteredshownBoxes
                    .where((e) => e.boxId != boxId)
                    .map((e) {
                  return DropdownMenuItem<String>(
                    value: e.boxId.toString(),
                    child: Text(e.boxName),
                  );
                }).toList(),
                value: controller.filteredshownBoxes.any((e) =>
                        e.boxId.toString() ==
                        controller.transferToBoxIdController.text)
                    ? controller.transferToBoxIdController.text
                    : null,
                onChanged: (value) {
                  controller.transferToBoxIdController.text = value!;
                },
              ),
              // SizedBox(
              //   height: 80.h,
              //   child: Row(
              //     children: [
              //       Flexible(
              //         child: CustomDropdownField(
              //           label: 'from',
              //           hint: 'اختر الصندوق',
              //           dropdownField:
              //               controller.boxesServes.shownBoxes.map((e) {
              //             return DropdownMenuItem<String>(
              //               value: e.boxId.toString(), // ✅ القيمة هنا = boxId
              //               child: Text(e.boxName), // المعروض للمستخدم
              //             );
              //           }).toList(),
              //           value: controller.boxesServes.shownBoxes.any((e) =>
              //                   e.boxId.toString() ==
              //                   controller.transferFromBoxIdController.text)
              //               ? controller.transferFromBoxIdController
              //                   .text // ✅ خليها نفس الـ id
              //               : null,
              //           onChanged: (value) {
              //             if (value != null) {
              //               controller.transferFromBoxIdController.text =
              //                   value; // ✅ خزّن الـ id
              //             }
              //           },
              //         ),
              //       ),
              //       SizedBox(width: 10.w),
              //       Flexible(
              //         child:
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'total'.tr,
                labelTextstyle:
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                hintText: 'totalExample',
                controller: controller.transferTotalController,
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isAddBoxLoading,
                text: 'apply',
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.whiteColor,
                    ),
                onPressed: () {
                  controller.transferBoxBalance(context, boxId.toString());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
