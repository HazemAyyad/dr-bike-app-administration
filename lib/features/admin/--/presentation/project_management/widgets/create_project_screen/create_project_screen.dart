import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/state_manager.dart';

import '../../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../../core/services/theme_service.dart';
import '../../../../../../../core/utils/app_colors.dart';
import '../../controllers/project_management_controller.dart';
import 'partnership_data.dart';

class CreateProjectScreen extends GetView<ProjectManagementController> {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( title: 'createProject', action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'projectName',
              labelColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor6
                  : AppColors.customGreyColor,
              hintText: 'projectNameExample',
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.projectNameController,
            ),
            SizedBox(height: 20.h),
            MediaUploadButton(
              title: 'uploadImage',
              allowedType: MediaType.image,
              onFilesChanged: (files) {
                controller.selectedFile = [files.first];
              },
            ),
            // UploadButton(
            //   title: 'uploadImage',
            //   textColor: Colors.black,
            //   selectedFile: controller.selectedFile,
            // ),
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'projectCost',
              labelColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor6
                  : AppColors.customGreyColor,
              hintText: 'projectCostExample',
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.projectNameController,
            ),
            SizedBox(height: 10.h),
            CustomDropdownField(
              isRequired: true,
              label: 'paymentMethod',
              hint: 'paymentMethodExample',
              items: controller.projectCostList,
              onChanged: (value) {
                controller.projectCost = value!;
              },
            ),
            SizedBox(height: 10.h),
            CustomDropdownField(
              isRequired: true,
              label: 'projectPartners',
              hint: 'projectPartnersExample',
              items: controller.projectPartnersList,
              onChanged: (value) {
                controller.projectPartners.value = value!;
              },
            ),
            // بيانات الشراكة
            partnershipData(controller),
            SizedBox(height: 10.h),
            CustomTextField(
              label: 'notes',
              labelColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor6
                  : AppColors.customGreyColor,
              hintText: 'projectNotesExample',
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.projectNameController,
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'projectDocuments',
              labelColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor6
                  : AppColors.customGreyColor,
              hintText: 'projectDocumentsExample',
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.projectNameController,
            ),
            SizedBox(height: 20.h),
            AppButton(
              text: 'addProject',
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.whiteColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              onPressed: controller.createProject,
              height: 40,
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}
