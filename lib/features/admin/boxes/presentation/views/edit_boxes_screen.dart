import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../controllers/boxes_controller.dart';
import '../widgets/task_details_transfer.dart';

class EditBoxesScreen extends StatefulWidget {
  const EditBoxesScreen({Key? key}) : super(key: key);

  @override
  State<EditBoxesScreen> createState() => _EditBoxesScreenState();
}

class _EditBoxesScreenState extends State<EditBoxesScreen> {
  late final BoxesController controller;
  late final String boxId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<BoxesController>();
    boxId = Get.arguments as String;
    controller.getboxDetails(boxId);
  }

  String? _appearDropdownValue(String raw) {
    return controller.appears.contains(raw) ? raw : null;
  }

  String? _currencyDropdownValue(String raw) {
    if (raw.isEmpty) return null;
    for (final element in controller.currency) {
      if (element.tr == raw) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                          value: _appearDropdownValue(
                            controller.editAppearController.text,
                          ),
                          items: controller.appears,
                          onChanged: (value) {
                            controller.editAppearController.text = value!;
                          },
                        ),
                        SizedBox(height: 10.h),
                        if (_currencyDropdownValue(
                              controller.editCurrencyController.text,
                            ) !=
                            null)
                          CustomDropdownField(
                            label: 'currencyy'.tr,
                            hint: 'currency'.tr,
                            value: _currencyDropdownValue(
                              controller.editCurrencyController.text,
                            ),
                            onChanged: (value) {
                              controller.editCurrencyController.text = value!;
                            },
                            items: controller.currency,
                            isEnabled: false,
                          )
                        else
                          CustomTextField(
                            label: 'currencyy'.tr,
                            hintText: 'currency'.tr,
                            controller: controller.editCurrencyController,
                            enabled: false,
                          ),
                        SizedBox(height: 30.h),
                        AppButton(
                          isSafeArea: false,
                          isLoading: controller.isAddBoxLoading,
                          text: 'editBox',
                          onPressed: () {
                            if ((controller. formKey.currentState as FormState)
                                .validate()) {
                              controller.editBox(
                                  context: context, boxId: boxId);
                            }
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
