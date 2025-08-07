import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../controllers/checks_controller.dart';

class NewCheckScreen extends GetView<ChecksController> {
  const NewCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNewCheck = Get.arguments['isNewCheck'] ?? true;

    return Scaffold(
      appBar: customAppBar(context,
          title: isNewCheck ? 'newCheck'.tr : 'newReceipt'.tr, action: false),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
            CustomTextField(
              label: 'checkValue',
              hintText: 'totalExample',
              controller: controller.checkValueController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              isRequired: true,
            ),
            SizedBox(height: isNewCheck ? 0 : 16.h),
            isNewCheck
                ? SizedBox()
                : CustomDropdownField(
                    label: 'beneficiaryName',
                    hint: 'customerNameExample',
                    items: controller.customers,
                    onChanged: (value) {
                      controller.customerController.text = value!;
                      print(
                          'Selected customer: ${controller.customerController.text}');
                    },
                    isRequired: true,
                  ),
            SizedBox(height: 16.h),
            CustomCalendar(
              isVisible: controller.isCalendarVisible,
              onTap: () => controller.toggleCalendar(),
              selectedDay: controller.selectedDay,
              label: 'due_date',
              isrequired: true,
            ),
            SizedBox(height: 16.h),
            CustomDropdownField(
              label: 'currencyy',
              hint: 'currencyExample',
              items: controller.currency,
              onChanged: (value) {
                controller.currencyController.text = value!;
                print(
                    'Selected currency: ${controller.currencyController.text}');
              },
              validator: (p0) {
                return null;
              },
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              label: 'checkNumber',
              hintText: 'checkNumberExample',
              controller: controller.checkNumberController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              isRequired: true,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              label: 'bankName',
              hintText: 'bankNameExample',
              controller: controller.bankNameController,
              textInputAction: TextInputAction.next,
              isRequired: true,
            ),
            SizedBox(height: 30.h),
            MediaUploadButton(
              title: 'checkFrontImage',
              allowedType: MediaType.image,
              onFilesChanged: (files) {
                controller.checkFrontImage = [files.first];
              },
            ),
            // UploadButton(
            //   title: 'checkFrontImage',
            //   selectedFile: controller.checkFrontImage,
            // ),
            SizedBox(height: 30.h),
            isNewCheck
                ? SizedBox()
                : MediaUploadButton(
                    title: 'checkBackImage',
                    allowedType: MediaType.image,
                    onFilesChanged: (files) {
                      controller.checkBackImage = [files.first];
                    },
                  ),
            // UploadButton(
            //   title: 'checkBackImage',
            //   selectedFile: controller.checkBackImage,
            // ),
            SizedBox(height: isNewCheck ? 0 : 50.h),
            AppButton(
              text: isNewCheck ? 'createCheck'.tr : 'cashTheChecks'.tr,
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w700,
                  ),
              onPressed: () {
                controller.cashTheChecks();
              },
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
