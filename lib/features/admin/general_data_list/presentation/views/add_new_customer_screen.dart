import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/state_manager.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/general_data_list_controller.dart';

class AddNewCustomerScreen extends GetView<GeneralDataListController> {
  const AddNewCustomerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( title: 'addNewCustomer', action: false),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    isRequired: true,
                    label: 'customerName',
                    hintText: 'customerNameExample',
                    controller: controller.customerNameController,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomDropdownField(
                    label: 'customerTypeTitle',
                    hint: 'customerNameExample',
                    items: controller.customerTypeList,
                    onChanged: (value) {
                      controller.selectedCustomerType.text = value!;
                    },
                    border: Border.all(color: AppColors.customGreyColor3),
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    label: 'customerPhoneNumber',
                    hintText: 'phoneNumberExample',
                    controller: controller.phoneNumberController,
                    validator: (p0) => null,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'alternatePhone',
                    hintText: 'phoneNumberExample',
                    controller: controller.secondPhoneNumberController,
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    label: 'facebookName',
                    hintText: 'facebookNameExample',
                    controller: controller.facebookNameController,
                    validator: (p0) => null,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'facebookLink',
                    hintText: 'facebookLinkExample',
                    controller: controller.facebookLinkController,
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    isRequired: true,
                    label: 'instagramName',
                    hintText: 'instagramNameExample',
                    controller: controller.instagramNameController,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'instagramLink',
                    hintText: 'instagramLinkExample',
                    controller: controller.instagramLinkController,
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            CustomDropdownField(
              label: 'closeContacts',
              hint: 'customerNameExample',
              items: controller.closePeopleList,
              onChanged: (value) {
                controller.closePeople.text = value!;
              },
              border: Border.all(color: AppColors.customGreyColor3),
              validator: (p0) => null,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Flexible(
                  child: UploadImageButton(
                    title: 'personalIdImage',
                    selectedFile: controller.personalIdImage,
                  ),
                ),
                SizedBox(width: 20.w),
                Flexible(
                  child: UploadImageButton(
                    title: 'carLicenseImage',
                    selectedFile: controller.carLicenseImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    label: 'residenceLocation',
                    hintText: 'residenceLocationExample',
                    controller: controller.residenceLocationController,
                    validator: (p0) => null,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'work',
                    hintText: 'workExample',
                    controller: controller.workController,
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    label: 'workLocation',
                    hintText: 'residenceLocationExample',
                    controller: controller.workLocationController,
                    validator: (p0) => null,
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomTextField(
                    label: 'closestPersonNumber',
                    hintText: 'phoneNumberExample',
                    controller: controller.closestPersonNumberController,
                    validator: (p0) => null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              label: 'closestPersonWork',
              hintText: 'workTitleExample',
              controller: controller.closestPersonWorkController,
              validator: (p0) => null,
            ),
            SizedBox(height: 20.h),
            AppButton(
              text: 'addCustomer',
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
              onPressed: controller.addNewCustomer,
              height: 40.h,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
