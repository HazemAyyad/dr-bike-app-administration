import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../controllers/official_papers_controller.dart';

class AddPaper extends GetView<OfficialPapersController> {
  const AddPaper({Key? key, this.fileId}) : super(key: key);

  final String? fileId;

  @override
  Widget build(BuildContext context) {
    if (fileId != null) {
      controller.fileController.text = fileId!;
    }
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
          child: SingleChildScrollView(
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
                if (controller.isEdit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupTextAndDiscr(
                        titleColor: AppColors.primaryColor,
                        title: '${'images'.tr} ${'or'.tr} ${'video'.tr}',
                        discription: '',
                      ),
                      SizedBox(height: 5.h),
                      GetBuilder<OfficialPapersController>(
                        builder: (controller) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...controller.paperFiles.map(
                                  (file) => Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5.w),
                                    child: Stack(
                                      children: [
                                        file.path.contains('.mp4')
                                            ? Icon(
                                                Icons.video_library_rounded,
                                                size: 80.sp,
                                                color: AppColors.primaryColor,
                                              )
                                            : file.path.contains('http')
                                                ? CachedNetworkImage(
                                                    imageUrl: file.path,
                                                    fit: BoxFit.cover,
                                                    height: 150.h,
                                                    width: 150.w,
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              color: AppColors
                                                                  .primaryColor),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                      Icons.error,
                                                      size: 50,
                                                      color: Colors.red,
                                                    ),
                                                  )
                                                : Image.file(
                                                    file,
                                                    height: 150.h,
                                                    width: 150.w,
                                                    fit: BoxFit.cover,
                                                  ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: InkWell(
                                            onTap: () {
                                              controller.paperFiles
                                                  .remove(file);
                                              controller.update();
                                            },
                                            child: const CircleAvatar(
                                              backgroundColor: Colors.red,
                                              radius: 14,
                                              child: Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                SizedBox(height: 20.h),
                MediaUploadButton(
                  isShowPreview: controller.isEdit ? false : true,
                  onFilesChanged: (files) {
                    final uniqueNewFiles = files.where((file) {
                      return !controller.paperFiles.any(
                        (existingFile) =>
                            existingFile.path.trim() == file.path.trim(),
                      );
                    }).toList();
                    controller.paperFiles.addAll(uniqueNewFiles);
                    controller.update();
                  },
                  title: 'uploadMedia'.tr,
                ),
                SizedBox(height: 20.h),
                CustomTextField(
                  label: 'notes'.tr,
                  hintText: 'notes'.tr,
                  controller: controller.notesController,
                  validator: (value) => null,
                  maxLines: 4,
                  minLines: 4,
                ),
                SizedBox(height: 20.h),
                AppButton(
                  isSafeArea: false,
                  isLoading: controller.isLoading,
                  text: 'add_document'.tr,
                  onPressed: () {
                    controller.addPaper();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
