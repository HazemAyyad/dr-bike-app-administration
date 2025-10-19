import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../../projects/presentation/widgets/product_details_widgets/sup_text_and_dis.dart';
import '../controllers/target_section_controller.dart';
import '../widgets/options_widget.dart';
import '../widgets/target_type_format_widget.dart';

class AddNewGoalScreen extends GetView<TargetSectionController> {
  const AddNewGoalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEdit.value ? 'editTarget' : 'addTarget',
        action: false,
      ),
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
              SizedBox(height: 10.h),
              CustomDropdownField(
                isRequired: true,
                label: 'targetType',
                hint: 'targetTypeExample',
                items: controller.targetTypes,
                value: controller.targetScopeController.text.isEmpty
                    ? null
                    : controller.targetScopeController.text,
                onChanged: (value) {
                  controller.targetScopeController.text = value!;
                },
              ),
              SizedBox(height: 10.h),
              CustomDropdownField(
                isRequired: true,
                label: 'targetTypeFormat',
                hint: 'targetTypeFormat',
                value: controller.targetTypeController.text.isEmpty
                    ? null
                    : controller.targetTypeController.text,
                items: controller.targetTypeList,
                onChanged: (value) {
                  controller.formController.clear();
                  controller.mainCategoriesIdController.clear();
                  controller.subCategoriesIdController.clear();
                  controller.productIdController.clear();
                  controller.customerAndSellerIdController.clear();
                  controller.employeeIdController.clear();
                  controller.boxIdController.clear();

                  controller.targetTypeController.text = value!;
                  controller.update();
                },
                isEnabled: !controller.isEdit.value,
              ),
              SizedBox(height: 10.h),
              const TargetTypeFormatWidget(),
              const OptionsWidget(),
              SizedBox(height: 10.h),
              GetBuilder<TargetSectionController>(
                builder: (controller) {
                  if (controller.productsIds.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 50.w),
                          height: 1.h,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor3,
                        ),
                        ...List.generate(
                          controller.productsIds.length,
                          (index) {
                            ProjectProductModel product =
                                controller.productsIds[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: SupTextAndDis(
                                    showLine: false,
                                    title: '${'productName'.tr} ${index + 1}',
                                    discription: product.productName,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controller.productsIds.removeAt(index);
                                    controller.update();
                                  },
                                  icon: Icon(
                                    Icons.highlight_remove_rounded,
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryColor,
                                    size: 25.sp,
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 50.w),
                          height: 1.h,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor3,
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                enabled: !controller.isEdit.value,
                label: 'targetValue',
                hintText: 'targetValueExample',
                controller: controller.targetValueController,
                keyboardType: TextInputType.number,
              ),
              if (controller.isEdit.value)
                Column(
                  children: [
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'currentValue',
                      hintText: 'targetValueExample',
                      controller: controller.currentValueController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              SizedBox(height: 10.h),
              CustomCalendar(
                label: 'date',
                selectedDay: controller.selectedTime,
                onTap: () {
                  controller.targetTimeController.value =
                      !controller.targetTimeController.value;
                },
                isVisible: controller.targetTimeController,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'notes',
                hintText: 'notesExample',
                controller: controller.notesController,
                validator: (p0) => null,
              ),
              SizedBox(height: 30.h),
              AppButton(
                isLoading: controller.isAddLoading,
                text: controller.isEdit.value ? 'editTarget' : 'addTarget',
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
