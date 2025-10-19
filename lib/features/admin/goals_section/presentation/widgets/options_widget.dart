import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../controllers/target_section_controller.dart';

class OptionsWidget extends StatelessWidget {
  const OptionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TargetSectionController>(
      builder: (controller) {
        if (controller.formController.text == 'people') {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: CustomCheckBox(
                      title: 'seller'.tr,
                      value: RxBool(!controller.isSeller.value == true),
                      onChanged: (val) {
                        if (controller.isEdit.value) {
                          return;
                        }
                        controller.customerAndSellerIdController.clear();
                        controller.isSeller.value = false;
                        controller.update();
                      },
                    ),
                  ),
                  Flexible(
                    child: CustomCheckBox(
                      title: 'customer'.tr,
                      value: RxBool(!controller.isSeller.value == false),
                      onChanged: (val) {
                        if (controller.isEdit.value) {
                          return;
                        }
                        controller.isSeller.value = true;
                        controller.update();
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
                value: (controller.customerAndSellerIdController.text.isEmpty)
                    ? null
                    : (controller.isSeller.value == false
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
                  controller.mainCategoriesIdController.clear();
                  controller.subCategoriesIdController.clear();
                  controller.productIdController.clear();
                  controller.employeeIdController.clear();
                  controller.boxIdController.clear();

                  controller.customerAndSellerIdController.text =
                      value.id.toString();
                },
                itemAsString: (f) => f.name,
                compareFn: (a, b) => a.id == b.id,
                isEnabled: !controller.isEdit.value,
              ),
              SizedBox(height: 10.h),
            ],
          );
        }
        if (controller.formController.text == 'products') {
          return CustomDropdownFieldWithSearch(
            tital: 'productName'.tr,
            hint: 'itemExample',
            items: controller.products,
            onChanged: (value) {
              if (value != null) {
                if (!controller.productsIds
                    .map((e) => e.productId)
                    .contains(value.id.toString())) {
                  controller.productsIds.add(
                    ProjectProductModel(
                      productId: value.id,
                      productName: value.nameAr,
                    ),
                  );
                }
                controller.update();
              }
            },
            itemAsString: (u) => u.nameAr,
            compareFn: (a, b) => a.id == b.id,
            validator: (value) => null,
            isEnabled: !controller.isEdit.value,
          );
        }

        if (controller.formController.text == 'main_categories') {
          return CustomDropdownFieldWithSearch(
            tital: 'main_categories',
            hint: 'main_categories',
            value: controller.mainCategoriesIdController.text.isEmpty
                ? null
                : controller.categories.firstWhereOrNull(
                    (e) =>
                        e.id.toString() ==
                        controller.mainCategoriesIdController.text,
                  ),
            items: controller.categories,
            onChanged: (value) {
              controller.subCategoriesIdController.clear();
              controller.productIdController.clear();
              controller.customerAndSellerIdController.clear();
              controller.employeeIdController.clear();
              controller.boxIdController.clear();

              controller.mainCategoriesIdController.text = value.id.toString();
            },
            itemAsString: (f) => f.nameAr,
            compareFn: (a, b) => a.id == b.id,
            validator: (value) => null,
            isEnabled: !controller.isEdit.value,
          );
        }
        if (controller.formController.text == 'sub_categories') {
          return CustomDropdownFieldWithSearch(
            tital: 'sub_categories',
            hint: 'sub_categories',
            value: controller.subCategoriesIdController.text.isEmpty
                ? null
                : controller.subCategories.firstWhereOrNull(
                    (e) =>
                        e.id.toString() ==
                        controller.subCategoriesIdController.text,
                  ),
            items: controller.subCategories,
            onChanged: (value) {
              controller.mainCategoriesIdController.clear();
              controller.productIdController.clear();
              controller.customerAndSellerIdController.clear();
              controller.employeeIdController.clear();
              controller.boxIdController.clear();

              controller.subCategoriesIdController.text = value.id.toString();
            },
            itemAsString: (f) => f.nameAr,
            compareFn: (a, b) => a.id == b.id,
            validator: (value) => null,
            isEnabled: !controller.isEdit.value,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
