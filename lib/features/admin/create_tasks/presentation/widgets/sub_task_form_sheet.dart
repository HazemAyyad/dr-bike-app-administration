import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';
import 'proof_media_type_selector.dart';

/// خلفية المودال — رمادي فاتح (مثل قسم الموظفين) بدون حواف بيضاء.
Color subTaskSheetBackground(BuildContext context) {
  final isDark = ThemeService.isDark.value;
  return isDark ? AppColors.customGreyColor : const Color(0xFFF5F6F8);
}

Color subTaskFieldFill(BuildContext context) {
  final isDark = ThemeService.isDark.value;
  return isDark ? AppColors.customGreyColor4 : const Color(0xFFEBECF0);
}

Future<void> showSubTaskFormSheet(
  BuildContext context, {
  required CreateTaskController controller,
  required String title,
  int? editIndex,
}) {
  if (editIndex != null) {
    controller.startEditSubTask(editIndex);
  } else {
    controller.prepareNewSubTask();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (sheetContext) => SubTaskFormSheet(
      title: title,
      controller: controller,
      onClose: () {
        controller.clearSubTaskForm();
        Navigator.of(sheetContext).pop();
      },
      onSave: () {
        if (controller.subTaskNameController.text.trim().isEmpty) return;
        controller.addSubTask();
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class SubTaskFormSheet extends StatelessWidget {
  const SubTaskFormSheet({
    Key? key,
    required this.title,
    required this.controller,
    required this.onClose,
    required this.onSave,
  }) : super(key: key);

  final String title;
  final CreateTaskController controller;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sheetBg = subTaskSheetBackground(context);
    final fieldFill = subTaskFieldFill(context);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Text(
                          controller.editingSubTaskIndex.value != null
                              ? 'editSubTask'.tr
                              : 'addSubTask'.tr,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.primaryColor,
                        size: 26.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        isRequired: true,
                        label: 'subTaskName',
                        hintText: 'subTaskNameExample',
                        controller: controller.subTaskNameController,
                        fillColor: fieldFill,
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        label: 'subTaskDescription',
                        hintText: 'subTaskNameExample',
                        controller: controller.subTaskDescriptionController,
                        validator: (_) => null,
                        fillColor: fieldFill,
                      ),
                      SizedBox(height: 12.h),
                      UploadImageButton(
                        selectedFile: controller.subTaskFile,
                        title: 'uploadImage',
                      ),
                      if (title == 'createNewEmployeeTask' ||
                          title == 'editEmployeeTask') ...[
                        SizedBox(height: 8.h),
                        Obx(
                          () => ProofMediaTypeSelector(
                            value: controller.subTaskProofMediaType.value,
                            onChanged: controller.setSubTaskProofMediaType,
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'cancel',
                              onPressed: onClose,
                              color: isDark
                                  ? AppColors.customGreyColor4
                                  : const Color(0xFFD1D5DB),
                              textColor: titleColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Obx(
                              () => AppButton(
                                text:
                                    controller.editingSubTaskIndex.value != null
                                        ? 'save'
                                        : 'add',
                                onPressed: onSave,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
