import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_phone_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/state_manager.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/follow_up_controller.dart';

class AddNewFollowCustomerScreen extends GetView<FollowUpController> {
  const AddNewFollowCustomerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'addNewCustomer', action: false),
      body: Form(
        key: controller.addNewCustomerFormKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'customerName',
              hintText: 'employeeNameExample',
              controller: controller.customerNameController,
            ),
            SizedBox(height: 20.h),
            CustomDropdownField(
              isRequired: true,
              label: 'customerTypeTitle',
              hint: 'customerTypeExample',
              items: controller.customerTypeList,
              onChanged: (value) {
                controller.customerTypeController.text = value!;
              },
              border: Border.all(color: AppColors.customGreyColor3),
            ),
            SizedBox(height: 20.h),
            CustomPhoneField(
              controller: controller.customerphoneController,
              label: 'phoneNumberTitle',
              hintText: 'phoneNumberExample',
              isRequired: true,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              label: 'notes',
              hintText: 'notesExample',
              controller: controller.customerNotesController,
              validator: (p0) => null,
            ),
            SizedBox(height: 20.h),
            AppButton(
              isLoading: controller.isLoading,
              text: 'addCustomer',
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
              onPressed: () => controller.addNewFollowCustomer(),
            ),
          ],
        ),
      ),
    );
  }
}
