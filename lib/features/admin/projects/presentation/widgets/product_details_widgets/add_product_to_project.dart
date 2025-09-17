import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/project_service.dart';

class AddProductToProject extends GetView<ProjectController> {
  const AddProductToProject({Key? key}) : super(key: key);

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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'addProduct'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
            ),
            SizedBox(height: 10.h),
            Form(
              key: controller.formKey,
              child: CustomDropdownFieldWithSearch(
                tital: 'productName'.tr,
                hint: 'itemExample',
                items: controller.products,
                onChanged: (value) {
                  if (value != null) {
                    controller.itemIdController.text = value.id.toString();
                  }
                },
                itemAsString: (u) => u.nameAr,
                compareFn: (a, b) => a.id == b.id,
              ),
            ),
            SizedBox(height: 20.h),
            AppButton(
              isLoading: controller.isLoading,
              isSafeArea: false,
              text: 'addProduct'.tr,
              onPressed: () {
                if (controller.formKey.currentState!.validate()) {
                  controller.addProductToProjectOrComplete(
                    context: context,
                    projectId: ProjectService().projectDetails.value!.id,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
