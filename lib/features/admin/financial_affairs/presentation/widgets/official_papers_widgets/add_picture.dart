import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/official_papers_controller.dart';

class AddPicture extends GetView<OfficialPapersController> {
  const AddPicture({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 10.h,
        ),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'add_important_images'.tr,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'image_name'.tr,
                      hintText: 'image_name'.tr,
                      controller: controller.pictureNameController,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Flexible(
                    child: CustomTextField(
                      label: 'image_description'.tr,
                      hintText: 'image_description'.tr,
                      controller: controller.pictureDescriptionController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              MediaUploadButton(
                onFilesChanged: (files) {
                  controller.pictureFiles = files;
                },
                title: 'uploadMedia'.tr,
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'add'.tr,
                onPressed: () {
                  controller.addPicture();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
