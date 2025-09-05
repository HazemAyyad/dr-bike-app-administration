import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../controllers/sales_controller.dart';

class NewCashProfitScreen extends GetView<SalesController> {
  const NewCashProfitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'newCashProfit'.tr, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 5.h),
              CustomTextField(
                isRequired: true,
                label: 'totalCost',
                hintText: 'totalExample',
                controller: controller.totalCostController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                minLines: 3,
                maxLines: 5,
                label: 'details',
                hintText: 'detailsExample',
                controller: controller.noteController,
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: 50.h),
              AppButton(
                isLoading: controller.isLoading,
                height: 45.h,
                width: 382.w,
                text: 'complete'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () {
                  controller.addProfitSale(context: context);
                },
              ),
            ],
          ),
        ),
      ),
      // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: AppButton(
      //   isLoading: controller.isLoading,
      //   height: 45.h,
      //   width: 382.w,
      //   text: 'complete'.tr,
      //   textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
      //         fontSize: 16.sp,
      //         fontWeight: FontWeight.w700,
      //         color: Colors.white,
      //       ),
      //   onPressed: () {
      //     controller.addProfitSale(context: context);
      //   },
      // ),
    );
  }
}
