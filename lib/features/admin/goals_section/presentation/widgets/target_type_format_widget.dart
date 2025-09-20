import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../controllers/target_section_controller.dart';

class TargetTypeFormatWidget extends GetView<TargetSectionController> {
  const TargetTypeFormatWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TargetSectionController>(
      builder: (controller) {
        if (controller.targetTypeFormatController.text == 'finish_tasks') {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => Flexible(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'seller'.tr,
                                  value: RxBool(
                                      !controller.isCustomer.value == true),
                                  onChanged: (val) {
                                    controller.customerAndSellerIdController
                                        .clear();
                                    controller.isCustomer.value = false;
                                  },
                                ),
                              ),
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'customer'.tr,
                                  value: RxBool(
                                      !controller.isCustomer.value == false),
                                  onChanged: (val) {
                                    controller.customerAndSellerIdController
                                        .text = '';
                                    controller.isCustomer.value = true;
                                  },
                                ),
                              )
                            ],
                          ),
                          CustomDropdownFieldWithSearch(
                            tital: controller.isCustomer.value == false
                                ? 'customerName'.tr
                                : 'sellerName'.tr,
                            hint: 'employeeNameExample',
                            items: controller.isCustomer.value == false
                                ? controller.allCustomersList
                                : controller.allSellersList,
                            value: (controller
                                    .customerAndSellerIdController.text.isEmpty)
                                ? null
                                : (controller.isCustomer.value == false
                                    ? controller.allCustomersList
                                        .firstWhereOrNull(
                                        (e) =>
                                            e.id.toString() ==
                                            controller
                                                .customerAndSellerIdController
                                                .text,
                                      )
                                    : controller.allSellersList
                                        .firstWhereOrNull(
                                        (e) =>
                                            e.id.toString() ==
                                            controller
                                                .customerAndSellerIdController
                                                .text,
                                      )),
                            onChanged: (value) {
                              controller.customerAndSellerIdController.text =
                                  value.id.toString();
                            },
                            itemAsString: (f) => f.name,
                            compareFn: (a, b) => a.id == b.id,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomDropdownFieldWithSearch(
                      tital: 'employee',
                      hint: 'employeeNameExample',
                      value: controller.employeeIdController.text.isEmpty
                          ? null
                          : controller.employeeList.firstWhereOrNull(
                              (e) =>
                                  e.id.toString() ==
                                  controller.employeeIdController.text,
                            ),
                      items: controller.employeeList,
                      onChanged: (value) {
                        controller.employeeIdController.text =
                            value.id.toString();
                      },
                      itemAsString: (f) => f.employeeName,
                      compareFn: (a, b) => a.id == b.id,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          );
        }
        if (controller.targetTypeFormatController.text == 'pay_person') {
          return Obx(
            () => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: CustomCheckBox(
                        title: 'seller'.tr,
                        value: RxBool(!controller.isCustomer.value == true),
                        onChanged: (val) {
                          controller.customerAndSellerIdController.clear();
                          controller.isCustomer.value = false;
                        },
                      ),
                    ),
                    Flexible(
                      child: CustomCheckBox(
                        title: 'customer'.tr,
                        value: RxBool(!controller.isCustomer.value == false),
                        onChanged: (val) {
                          controller.customerAndSellerIdController.text = '';
                          controller.isCustomer.value = true;
                        },
                      ),
                    )
                  ],
                ),
                CustomDropdownFieldWithSearch(
                  tital: controller.isCustomer.value == false
                      ? 'customerName'.tr
                      : 'sellerName'.tr,
                  hint: 'employeeNameExample',
                  items: controller.isCustomer.value == false
                      ? controller.allCustomersList
                      : controller.allSellersList,
                  value: (controller.customerAndSellerIdController.text.isEmpty)
                      ? null
                      : (controller.isCustomer.value == false
                          ? controller.allCustomersList.firstWhereOrNull(
                              (e) =>
                                  e.id.toString() ==
                                  controller.customerAndSellerIdController.text,
                            )
                          : controller.allSellersList.firstWhereOrNull(
                              (e) =>
                                  e.id.toString() ==
                                  controller.customerAndSellerIdController.text,
                            )),
                  onChanged: (value) {
                    controller.customerAndSellerIdController.text =
                        value.id.toString();
                  },
                  itemAsString: (f) => f.name,
                  compareFn: (a, b) => a.id == b.id,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        }
        if (controller.targetTypeFormatController.text == 'deposit_to_box') {
          return Column(
            children: [
              CustomDropdownFieldWithSearch(
                tital: 'box',
                hint: 'boxNameExample',
                value: controller.boxIdController.text.isEmpty
                    ? null
                    : controller.shownBoxes.firstWhereOrNull(
                        (e) =>
                            e.boxId.toString() ==
                            controller.boxIdController.text,
                      ),
                items: controller.shownBoxes,
                onChanged: (value) {
                  controller.boxIdController.text = value.boxId.toString();
                },
                itemAsString: (f) => f.boxName,
                compareFn: (a, b) => a.boxId == b.boxId,
              ),
              SizedBox(height: 20.h),
            ],
          );
        }
        return Column(
          children: [
            CustomDropdownField(
              label: 'options',
              hint: 'options',
              value: controller.optionsController.text.isEmpty
                  ? null
                  : controller.optionsController.text,
              items: controller.options,
              onChanged: (value) {
                controller.optionsController.text = value!;
              },
            ),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }
}
