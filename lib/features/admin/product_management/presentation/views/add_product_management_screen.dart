import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../maintenance/presentation/widgets/custom_line_steps_widget.dart';
import '../../../maintenance/presentation/widgets/next_back_button.dart';
import '../controllers/product_management_controller.dart';
import '../widgets/product_management_widget.dart';

class AddProductManagementScreen extends StatelessWidget {
  const AddProductManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'addNewProductt', action: false),
      body: GetBuilder<ProductManagementController>(builder: (controller) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                CustomLineSteps(
                  timeLineSteps: controller.timeLineSteps,
                  selectedStep: controller.selectedStep,
                  changeSelected: (step) =>
                      controller.changeSelected(step, isSecond: false),
                ),
                SizedBox(height: 20.h),
                CustomLineSteps(
                  width: 50.w,
                  timeLineSteps: controller.timeLineSteps2,
                  selectedStep: controller.selectedStep2,
                  changeSelected: (step) =>
                      controller.changeSelected(step, isSecond: true),
                ),
                SizedBox(height: 20.h),
                GetBuilder<ProductManagementController>(
                  builder: (controller) {
                    if (controller.isEdit.value) {
                      return ProductManagementWidget(
                        currentStep: controller.currentStep.toString(),
                        productImage: controller.productImage,
                        productName: controller.productName,
                        isEdit: true,
                      );
                    }
                    return Column(
                      children: [
                        CustomDropdownFieldWithSearch(
                          tital: 'productName',
                          hint: 'itemExample',
                          items: controller.products,
                          onChanged: (value) {
                            controller.productIdController.text =
                                value.id.toString();
                          },
                          itemAsString: (item) => item.nameAr,
                          compareFn: (item1, item2) => item1.id == item2.id,
                        ),
                        SizedBox(height: 10.h),
                        CustomTextField(
                          label: 'details',
                          hintText: 'detailsExample',
                          controller: controller.descriptionController,
                          validator: (p0) => null,
                          maxLines: 5,
                          minLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),
                NextBackButton(
                  isLoading: controller.isLoading,
                  endTitle: 'delivered',
                  totalSteps: controller.totalSteps.obs,
                  selectedStep: controller.currentGlobalStep.obs,
                  onPressedBack: () {
                    if (controller.formKey.currentState!.validate()) {
                      controller.prevStep();
                    }
                  },
                  onPressedNext: () {
                    if (controller.formKey.currentState!.validate()) {
                      controller.nextStep();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
