import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/target_section_controller.dart';

class TargetTypeFormatWidget extends GetView<TargetSectionController> {
  const TargetTypeFormatWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TargetSectionController>(
      builder: (controller) {
        if (controller.targetTypeController.text == 'pay_person') {
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
                                  value: controller
                                          .employeeIdController.text.isNotEmpty
                                      ? RxBool(false)
                                      : RxBool(
                                          !controller.isSeller.value == true),
                                  onChanged: (val) {
                                    if (controller.isEdit.value) {
                                      return;
                                    }
                                    controller.customerAndSellerIdController
                                        .clear();
                                    controller.isSeller.value = false;
                                  },
                                ),
                              ),
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'customer'.tr,
                                  value: controller
                                          .employeeIdController.text.isNotEmpty
                                      ? RxBool(false)
                                      : RxBool(
                                          !controller.isSeller.value == false),
                                  onChanged: (val) {
                                    if (controller.isEdit.value) {
                                      return;
                                    }
                                    controller.customerAndSellerIdController
                                        .text = '';
                                    controller.isSeller.value = true;
                                  },
                                ),
                              )
                            ],
                          ),
                          CustomDropdownFieldWithSearch(
                            tital: controller.isSeller.value == false
                                ? 'customerName'.tr
                                : 'sellerName'.tr,
                            hint: 'employeeNameExample',
                            items: controller.isSeller.value == false
                                ? controller.allCustomersList
                                : controller.allSellersList,
                            value: (controller
                                    .customerAndSellerIdController.text.isEmpty)
                                ? null
                                : (controller.isSeller.value == false
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
                              controller.mainCategoriesIdController.clear();
                              controller.subCategoriesIdController.clear();
                              controller.productIdController.clear();
                              controller.employeeIdController.clear();
                              controller.boxIdController.clear();

                              controller.customerAndSellerIdController.text =
                                  value.id.toString();
                            },
                            itemAsString: (f) => f.name,
                            validator: (value) => null,
                            compareFn: (a, b) => a.id == b.id,
                            isEnabled: !controller.isEdit.value,
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
                      validator: (value) => null,
                      isEnabled: !controller.isEdit.value,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          );
        }
        if (controller.targetTypeController.text == 'finish_tasks') {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                        controller.mainCategoriesIdController.clear();
                        controller.subCategoriesIdController.clear();
                        controller.productIdController.clear();
                        controller.customerAndSellerIdController.clear();
                        controller.boxIdController.clear();

                        controller.employeeIdController.text =
                            value.id.toString();
                      },
                      itemAsString: (f) => f.employeeName,
                      compareFn: (a, b) => a.id == b.id,
                      validator: (value) => null,
                      isEnabled: !controller.isEdit.value,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.ADDNEWEMPLOYEESCREEN, arguments: {
                      'AddNewEmployeeScreen': 'addNewEmployee',
                    })?.then((value) => controller.getEmployee()),
                    icon: Icon(
                      Icons.add_circle_sharp,
                      color: AppColors.primaryColor,
                      size: 35.sp,
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.h),
            ],
          );
          // Obx(
          //   () => Column(
          //     children: [
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           Flexible(
          //             child: CustomCheckBox(
          //               title: 'seller'.tr,
          //               value: RxBool(!controller.isCustomer.value == true),
          //               onChanged: (val) {
          //                 controller.customerAndSellerIdController.clear();
          //                 controller.isCustomer.value = false;
          //               },
          //             ),
          //           ),
          //           Flexible(
          //             child: CustomCheckBox(
          //               title: 'customer'.tr,
          //               value: RxBool(!controller.isCustomer.value == false),
          //               onChanged: (val) {
          //                 controller.customerAndSellerIdController.text = '';
          //                 controller.isCustomer.value = true;
          //               },
          //             ),
          //           )
          //         ],
          //       ),
          //       CustomDropdownFieldWithSearch(
          //         tital: controller.isCustomer.value == false
          //             ? 'customerName'.tr
          //             : 'sellerName'.tr,
          //         hint: 'employeeNameExample',
          //         items: controller.isCustomer.value == false
          //             ? controller.allCustomersList
          //             : controller.allSellersList,
          //         value: (controller.customerAndSellerIdController.text.isEmpty)
          //             ? null
          //             : (controller.isCustomer.value == false
          //                 ? controller.allCustomersList.firstWhereOrNull(
          //                     (e) =>
          //                         e.id.toString() ==
          //                         controller.customerAndSellerIdController.text,
          //                   )
          //                 : controller.allSellersList.firstWhereOrNull(
          //                     (e) =>
          //                         e.id.toString() ==
          //                         controller.customerAndSellerIdController.text,
          //                   )),
          //         onChanged: (value) {
          //           controller.customerAndSellerIdController.text =
          //               value.id.toString();
          //         },
          //         itemAsString: (f) => f.name,
          //         compareFn: (a, b) => a.id == b.id,
          //       ),
          //       SizedBox(height: 20.h),
          //     ],
          //   ),
          // );
        }
        if (controller.targetTypeController.text == 'deposit_to_box') {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: CustomDropdownFieldWithSearch(
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
                        controller.mainCategoriesIdController.clear();
                        controller.subCategoriesIdController.clear();
                        controller.productIdController.clear();
                        controller.customerAndSellerIdController.clear();
                        controller.employeeIdController.clear();

                        controller.boxIdController.text =
                            value.boxId.toString();
                      },
                      itemAsString: (f) => f.boxName,
                      compareFn: (a, b) => a.boxId == b.boxId,
                      isEnabled: !controller.isEdit.value,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.CREATEBOXESSCREEN)?.then(
                      (value) => controller.getShowBoxes(),
                    ),
                    icon: Icon(
                      Icons.add_circle_sharp,
                      color: AppColors.primaryColor,
                      size: 35.sp,
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.h),
            ],
          );
        }
        if (controller.targetTypeController.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            CustomDropdownField(
              label: 'options',
              hint: 'options',
              value: controller.formController.text.isEmpty
                  ? null
                  : controller.formController.text,
              items: controller.targetTypeController.text ==
                          'total_sell_values' ||
                      controller.targetTypeController.text == 'net_profit' ||
                      controller.targetTypeController.text == 'sell_pieces' ||
                      controller.targetTypeController.text == 'purchase_pieces'
                  ? controller.options1
                  : controller.targetTypeController.text ==
                          'total_purchase_values'
                      ? controller.options3
                      : [],
              isEnabled: !controller.isEdit.value,
              onChanged: (value) {
                controller.productsIds.clear();
                controller.mainCategoriesIdController.clear();
                controller.subCategoriesIdController.clear();
                controller.productIdController.clear();
                controller.customerAndSellerIdController.clear();
                controller.employeeIdController.clear();
                controller.boxIdController.clear();

                controller.formController.text = value!;
                controller.update();
              },
            ),
            // SizedBox(height: 10.h),
          ],
        );
      },
    );
  }
}
