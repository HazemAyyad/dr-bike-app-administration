import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';

class NewCashProfitScreen extends GetView<SalesController> {
  const NewCashProfitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'newCashProfit'.tr, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 5.h),
            CustomTextField(
              isRequired: true,
              label: 'totalCost',
              labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
              hintText: 'totalExample',
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
              controller: controller.totalCostController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              minLines: 3,
              maxLines: 5,
              label: 'details',
              labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
              hintText: 'detailsExample',
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
              controller: controller.noteController,
            ),
          ],
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AppButton(
        height: 45.h,
        width: 382.w,
        text: 'complete'.tr,
        textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
        onPressed: () {},
      ),
    );
  }
}
