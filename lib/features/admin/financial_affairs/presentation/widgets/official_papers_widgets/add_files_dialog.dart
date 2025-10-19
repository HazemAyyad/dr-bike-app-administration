import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/official_papers_controller.dart';

class AddFilesDialog extends GetView<OfficialPapersController> {
  const AddFilesDialog({
    Key? key,
    required this.title,
    required this.label,
    required this.hintText,
    required this.onPressed,
  }) : super(key: key);

  final String title;
  final String label;
  final String hintText;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.tr,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor
                          : AppColors.secondaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: controller.safeNameController,
                label: label.tr,
                hintText: hintText.tr,
                validator: (value) {
                  if (value!.isEmpty) {
                    return label.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                isSafeArea: false,
                text: 'create'.tr,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
