import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../controllers/boxes_controller.dart';
import '../widgets/task_details_transfer.dart';

class EditBoxesScreen extends GetView<BoxesController> {
  const EditBoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String boxId = Get.arguments;

    return Scaffold(
      appBar: CustomAppBar(title: 'editBox'.tr, action: false),
      body: GetBuilder<BoxesController>(
        builder: (controller) {
          return controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: controller.formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        CustomTextField(
                          isRequired: true,
                          label: 'boxName'.tr,
                          hintText: 'BalanceTransferExample',
                          controller: controller.editBoxNameController,
                        ),
                        SizedBox(height: 10.h),
                        CustomTextField(
                          label: 'startBalance'.tr,
                          hintText: 'startBalanceExample',
                          controller: controller.editStartBalanceController,
                          keyboardType: TextInputType.number,
                          enabled: false,
                        ),
                        SizedBox(height: 10.h),
                        CustomDropdownField(
                          label: 'appear',
                          hint: 'visible',
                          value: controller.editAppearController.text,
                          items: controller.appears,
                          onChanged: (value) {
                            controller.editAppearController.text = value!;
                          },
                        ),
                        SizedBox(height: 10.h),
                        CustomDropdownField(
                          label: 'currencyy'.tr,
                          hint: 'currency'.tr,
                          value: controller.editCurrencyController.text.isEmpty
                              ? null
                              : controller.currency.firstWhere(
                                  (element) =>
                                      element.tr ==
                                      controller.editCurrencyController.text,
                                ),
                          onChanged: (value) {
                            controller.editCurrencyController.text = value!;
                          },
                          items: controller.currency,
                          isEnabled: false,
                        ),
                        SizedBox(height: 30.h),
                        AppButton(
                          isSafeArea: false,
                          isLoading: controller.isAddBoxLoading,
                          text: 'editBox',
                          onPressed: () {
                            controller.editBox(context, boxId);
                          },
                          textStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const TaskDetailsTransfer(),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
