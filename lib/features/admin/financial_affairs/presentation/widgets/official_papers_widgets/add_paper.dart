import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/finacial_service.dart';
import '../../controllers/official_papers_controller.dart';

class AddPaper extends GetView<OfficialPapersController> {
  const AddPaper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
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
                    'add_new_document'.tr,
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
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'document_name'.tr,
                hintText: 'document_example'.tr,
                controller: controller.paperNameController,
              ),
              SizedBox(height: 10.h),
              CustomDropdownField(
                label: 'select_file'.tr,
                hint: 'select_file'.tr,
                dropdownField: FinacialService()
                    .files
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.id.toString(),
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                items: FinacialService().files.map((e) => e.name).toList(),
                onChanged: (value) {
                  controller.fileController.text = value!;
                },
              ),
              // SizedBox(height: 10.h),
              // Row(
              //   children: [
              //     Flexible(
              //       child: CustomDropdownField(
              //         label: 'select_file_box'.tr,
              //         hint: 'select_file_box'.tr,
              //         // value: controller.fileBoxController.text,
              //         items: const ['pdf', 'image'],
              //         onChanged: (value) {
              //           // controller.fileBoxController.text = value!;
              //         },
              //       ),
              //     ),
              //     SizedBox(width: 15.w),
              //     Flexible(
              //       child: CustomDropdownField(
              //         label: 'safes'.tr,
              //         hint: 'safes'.tr,
              //          value: FinacialService()
              //              .files
              //              .where((e) =>
              //                  e.id.toString() == controller.fileController.text)
              //              .first
              //              .name
              //              .toString(),
              //         items:
              //             FinacialService().files.map((e) => e.name).toList(),
              //         onChanged: (value) {
              //           // controller.safeController.text = value!;
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(height: 20.h),
              MediaUploadButton(
                onFilesChanged: (files) {
                  controller.paperFiles = files;
                },
                title: 'uploadMedia'.tr,
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                label: 'notes'.tr,
                hintText: 'notes'.tr,
                controller: controller.notesController,
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'add_document'.tr,
                onPressed: () {
                  controller.addPaper(fileId: controller.fileController.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
