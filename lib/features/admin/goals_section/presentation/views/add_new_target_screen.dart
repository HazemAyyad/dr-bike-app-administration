import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../controllers/target_section_controller.dart';
import '../widgets/target_type_format_widget.dart';

class AddNewGoalScreen extends GetView<TargetSectionController> {
  const AddNewGoalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'addNewTarget', action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 10.h),
              CustomTextField(
                isRequired: true,
                label: 'targetName',
                hintText: 'targetNameExample',
                controller: controller.targetNameController,
              ),
              SizedBox(height: 20.h),
              CustomDropdownField(
                label: 'targetType',
                hint: 'targetTypeExample',
                items: controller.targetTypes,
                value: controller.targetTypeController.text.isEmpty
                    ? null
                    : controller.targetTypeController.text,
                onChanged: (value) {
                  controller.targetTypeController.text = value!;
                },
              ),
              SizedBox(height: 20.h),
              CustomDropdownField(
                label: 'targetTypeFormat',
                hint: 'targetTypeFormat',
                value: controller.targetTypeFormatController.text.isEmpty
                    ? null
                    : controller.targetTypeFormatController.text,
                items: controller.targetTypeFormat,
                onChanged: (value) {
                  controller.targetTypeFormatController.text = value!;
                  controller.update();
                },
                validator: (p0) => null,
              ),
              SizedBox(height: 20.h),
              const TargetTypeFormatWidget(),
              CustomTextField(
                label: 'targetValue',
                hintText: 'targetValueExample',
                controller: controller.targetValueController,
              ),
              if (controller.isEdit.value)
                Column(
                  children: [
                    SizedBox(height: 20.h),
                    CustomTextField(
                      label: 'currentValue',
                      hintText: 'targetValueExample',
                      controller: controller.currentValueController,
                    ),
                  ],
                ),
              SizedBox(height: 20.h),
              CustomTextField(
                label: 'notes',
                hintText: 'notesExample',
                controller: controller.notesController,
                validator: (p0) => null,
              ),
              SizedBox(height: 30.h),
              AppButton(
                isLoading: controller.isAddLoading,
                text: 'addTarget',
                onPressed: () {
                  if (controller.formKey.currentState!.validate()) {
                    controller.addGoal(context);
                  }
                },
                height: 40.h,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
