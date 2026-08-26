import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/target_section_controller.dart';
import 'goal_products_picker_sheet.dart';

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
                        controller.getAllCustomersAndSellers();
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
                        controller.getAllCustomersAndSellers();
                        controller.isSeller.value = true;
                        controller.update();
                      },
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: CustomDropdownFieldWithSearch(
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
                              ? controller.allCustomersList.firstWhereOrNull(
                                  (e) =>
                                      e.id.toString() ==
                                      controller
                                          .customerAndSellerIdController.text,
                                )
                              : controller.allSellersList.firstWhereOrNull(
                                  (e) =>
                                      e.id.toString() ==
                                      controller
                                          .customerAndSellerIdController.text,
                                )),
                      onChanged: (value) {
                        controller.mainCategoriesIdController.clear();
                        controller.subCategoriesIdController.clear();
                        controller.storeSectionIdController.clear();
                        controller.productIdController.clear();
                        controller.employeeIdController.clear();
                        controller.boxIdController.clear();

                        controller.customerAndSellerIdController.text =
                            value.id.toString();
                        controller.update();
                      },
                      itemAsString: (f) => f.name,
                      compareFn: (a, b) => a.id == b.id,
                      isEnabled: true,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN, arguments: {
                      'sellerId': '',
                      'employeeId': '',
                      'employeeType':
                          controller.isSeller.value ? 'customer' : 'seller',
                    })?.then((value) => controller.getAllCustomersAndSellers()),
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
        if (controller.formController.text == 'products') {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: AppColors.operationalPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () => showGoalProductsPickerSheet(context),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(
                    controller.productsIds.isEmpty
                        ? 'chooseProducts'.tr
                        : '${'selectedProducts'.tr}: ${controller.productsIds.length}',
                  ),
                ),
              ),
              GoalSelectedProductsTable(
                key: ValueKey(
                  controller.productsIds
                      .map((product) => product.productId)
                      .join(','),
                ),
              ),
            ],
          );
        }

        if (controller.formController.text == 'store_sections') {
          return CustomDropdownFieldWithSearch(
            tital: 'store_sections'.tr,
            hint: 'store_sections'.tr,
            value: controller.storeSectionIdController.text.isEmpty
                ? null
                : controller.storeSections.firstWhereOrNull(
                    (e) =>
                        e.id.toString() ==
                        controller.storeSectionIdController.text,
                  ),
            items: controller.storeSections,
            onChanged: (value) {
              controller.mainCategoriesIdController.clear();
              controller.subCategoriesIdController.clear();
              controller.customerAndSellerIdController.clear();
              controller.employeeIdController.clear();
              controller.boxIdController.clear();
              controller.productIdController.clear();
              controller.productsIds.clear();

              controller.storeSectionIdController.text = value.id.toString();
              controller.update();
            },
            itemAsString: (f) => f.name,
            compareFn: (a, b) => a.id == b.id,
            validator: (value) => null,
            isEnabled: true,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
