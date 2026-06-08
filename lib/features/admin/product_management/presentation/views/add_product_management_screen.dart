import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/product_management_controller.dart';
import '../widgets/product_development_product_picker.dart';
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
                SizedBox(height: 16.h),
                ProductDevelopmentStepper(
                  firstSteps: controller.timeLineSteps,
                  secondSteps: controller.timeLineSteps2,
                  activeStep: controller.currentGlobalStep,
                ),
                SizedBox(height: 30.h),
                if (controller.isEdit.value)
                  ProductManagementWidget(
                    currentStep: controller.currentStep.toString(),
                    rating: controller.currentStep.toDouble(),
                    productImage: controller.productImage,
                    productImageUrls: controller.productImageUrls,
                    productName: controller.productName,
                    isEdit: true,
                  ),
                if (controller.isEdit.value) SizedBox(height: 12.h),
                if (!controller.isEdit.value)
                  ProductDevelopmentProductPicker(
                    products: controller.products,
                    selectedProduct: controller.selectedProduct,
                    onChanged: (value) {
                      controller.selectProductForDevelopment(value);
                    },
                  ),
                if (!controller.isEdit.value) SizedBox(height: 12.h),
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
                SizedBox(height: 20.h),
                Row(
                  children: [
                    if (controller.canGoPrevious)
                      Expanded(
                        child: AppButton(
                          text: 'previous'.tr,
                          color: AppColors.customGreyColor5,
                          borderRadius: BorderRadius.circular(6.r),
                          height: 40.h,
                          width: double.infinity,
                          isSafeArea: false,
                          onPressed: () async => controller.prevStep(),
                        ),
                      ),
                    if (controller.canGoPrevious) SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        isLoading: controller.isLoading,
                        text: controller.nextButtonLabel,
                        color: controller.currentStep >= controller.totalSteps
                            ? Colors.green
                            : AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(6.r),
                        height: 40.h,
                        width: double.infinity,
                        isSafeArea: false,
                        onPressed: () {
                          if (controller.formKey.currentState!.validate()) {
                            controller.nextStep();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
