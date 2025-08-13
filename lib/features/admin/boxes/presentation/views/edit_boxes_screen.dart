import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/boxes_controller.dart';

class EditBoxesScreen extends GetView<BoxesController> {
  const EditBoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( title: 'editBox'.tr, action: false),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 10.h),
          CustomTextField(
            isRequired: true,
            label: 'boxName'.tr,
            hintText: 'BalanceTransferExample',
            controller: controller.editBoxNameController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            label: 'startBalance'.tr,
            hintText: 'startBalanceExample',
            controller: controller.editStartBalanceController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20.h),
          CustomDropdownField(
            label: 'appear',
            hint: 'visible',
            items: controller.appears,
            onChanged: (value) {
              controller.appearController.text = value!;
            },
          ),
          SizedBox(height: 30.h),
          // Container(
          //   decoration: BoxDecoration(
          //     border: Border.all(
          //       color: AppColors.primaryColor,
          //       width: 1.w,
          //     ),
          //   ),
          // ),
          SizedBox(height: 30.h),
          AppButton(
            text: 'editBox',
            onPressed: () {},
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          )
        ],
      ),
    );
  }
}
