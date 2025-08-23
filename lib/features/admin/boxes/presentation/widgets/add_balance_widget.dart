import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';

class AddBalanceWidget extends GetView<BoxesController> {
  const AddBalanceWidget({Key? key, required this.boxId}) : super(key: key);

  final int boxId;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
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
                Icon(
                  Icons.add,
                  size: 25.h,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 5.w),
                Text(
                  'addBalance'.tr,
                  style: textStyle.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // CustomDropdownField(
            //   label: 'boxName',
            //   labelTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            //         color: AppColors.primaryColor,
            //         fontSize: 15.sp,
            //         fontWeight: FontWeight.w700,
            //       ),
            //   hint: 'boxNameExample',
            //   items: controller.boxes
            //       .map((box) => box['boxName'] as String)
            //       .toList(),
            //   onChanged: (value) {
            //     controller.addBalanceBoxNameController.text = value!;
            //   },
            // ),
            Text(boxId.toString(), style: textStyle.copyWith(fontSize: 15.sp)),
            SizedBox(height: 10.h),
            Form(
              key: controller.formKey,
              child: CustomTextField(
                label: 'value'.tr,
                labelTextstyle:
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                hintText: 'totalExample',
                controller: controller.addBalanceValueController,
              ),
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
                controller.addBoxBalance(
                  context,
                  boxId.toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
