import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';
import 'build_sub_task_image.dart';

class AddSubTask extends GetView<CreateTaskController> {
  const AddSubTask({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => controller.toggleSubtasksList(),
          icon: Obx(
            () => AnimatedRotation(
              turns: controller.isSubtasksListVisible.value
                  ? -0.125
                  : 0, // 0.125 = 45 درجة
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.add_rounded,
                key: ValueKey(controller.isSubtasksListVisible.value),
                color: AppColors.primaryColor,
                size: 20.sp,
              ),
            ),
          ),
          label: Text(
            'addSubTask'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        // قائمة المهام الفرعية
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.subTasks
                .map(
                  (task) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.close, size: 20.sp, color: Colors.red),
                          onPressed: () => controller.subTasks.remove(task),
                        ),
                        buildSubTaskImage(task['subTaskImage']),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(
                                horizontal: -4, vertical: -4),
                            minLeadingWidth: 0,
                            minVerticalPadding: 0,
                            horizontalTitleGap: 0,
                            title: Text(
                              task['subTaskName'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            subtitle: Text(
                              task['subTaskdescription'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: AppColors.customGreyColor5,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Obx(
          () => AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: child,
                );
              },
              child: controller.isSubtasksListVisible.value
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المهمة الفرعية
                        Row(
                          children: [
                            Flexible(
                              child: CustomTextField(
                                isRequired: true,
                                label: 'subTaskName',
                                hintText: 'subTaskNameExample',
                                controller: controller.subTaskNameController,
                              ),
                            ),
                            SizedBox(width: 15.w),
                            // وصف المهمة الفرعية
                            Flexible(
                              child: CustomTextField(
                                label: 'subTaskDescription',
                                hintText: 'subTaskNameExample',
                                controller:
                                    controller.subTaskDescriptionController,
                                validator: (p0) => null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.h),
                        UploadImageButton(
                          selectedFile: controller.subTaskFile,
                          title: 'uploadImage',
                        ),
                        // title == 'createNewEmployeeTask'
                        //     ? CustomCheckBox(
                        //         value: controller.requireSubTasImage,
                        //         title: 'requireImage',
                        //         onChanged: (value) {
                        //           controller.requireSubTasImage.value = value!;
                        //         },
                        //       )
                        //     : const SizedBox.shrink(),
                        SizedBox(height: 15.h),
                        // أزرار الإجراءات
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              AppButton(
                                text: 'add',
                                onPressed: controller.addSubTask,
                                color: controller.cancelButtonColor.value,
                              ),
                              AppButton(
                                text: 'cancel',
                                onPressed: () {
                                  controller.isSubtasksListVisible.value =
                                      false;
                                  controller.cancelButtonColor.value =
                                      Get.isDarkMode
                                          ? AppColors.darkColor
                                          : AppColors.whiteColor;
                                },
                                color: controller.cancelButtonColor.value,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(key: ValueKey('empty')),
            ),
          ),
        ),
      ],
    );
  }
}
