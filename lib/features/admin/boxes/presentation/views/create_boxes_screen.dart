import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/boxes_controller.dart';

class CreateBoxesScreen extends GetView<BoxesController> {
  const CreateBoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( title: 'newBox'.tr, action: false),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'boxName'.tr,
              hintText: 'BalanceTransferExample',
              controller: controller.createBoxNameController,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              label: 'startBalance'.tr,
              hintText: 'startBalanceExample',
              controller: controller.createStartBalanceController,
              keyboardType: TextInputType.number,
              validator: (p0) => null,
            ),
            SizedBox(height: 30.h),
            SizedBox(height: 30.h),
            AppButton(
              text: 'createBox',
              onPressed: () {
                if ((controller.formKey.currentState as FormState).validate()) {
                  print('done');
                }
              },
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
