import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/project_details_model.dart';
import '../../controllers/project_controller.dart';
import '../product_details_widgets/sup_text_and_dis.dart';
import '../product_details_widgets/show_image.dart';

class FirstStep extends GetView<ProjectController> {
  const FirstStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: CustomTextField(
                isRequired: true,
                label: 'projectName',
                hintText: 'projectNameExample',
                controller: controller.projectNameController,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: CustomTextField(
                isRequired: true,
                label: 'projectCost',
                hintText: 'projectCostExample',
                controller: controller.projectCostController,
                keyboardType: TextInputType.number,
                // validator: (value) => null,
              ),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        GetBuilder<ProjectController>(
          builder: (controller) {
            if (controller.productsIds.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                Container(
                  margin:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 50.w),
                  height: 1.h,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor3,
                ),
                ...List.generate(
                  controller.productsIds.length,
                  (index) {
                    ProjectProductModel product = controller.productsIds[index];
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
                  margin:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 50.w),
                  height: 1.h,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor3,
                ),
              ],
            );
          },
        ),

        CustomDropdownFieldWithSearch(
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
        ),
        if (controller.isEdit.value) ShowImage(list: controller.projectImages),
        SizedBox(height: 20.h),
        MediaUploadButton(
          title: 'projectOrProductsImages',
          allowedType: MediaType.image,
          onFilesChanged: (files) {
            for (var file in files) {
              if (!controller.projectImages.contains(file)) {
                controller.projectImages.add(file);
              }
            }
          },
        ),
        SizedBox(height: 15.h),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: CustomCheckBox(
                  title: 'seller'.tr,
                  value: RxBool(
                      !controller.selectedCustomersSellers.value == true),
                  onChanged: (val) {
                    controller.getAllCustomersAndSellers();
                    controller.selectedCustomersSellers.value = false;
                  },
                ),
              ),
              Flexible(
                child: CustomCheckBox(
                  title: 'customer'.tr,
                  value: RxBool(
                      !controller.selectedCustomersSellers.value == false),
                  onChanged: (val) {
                    controller.getAllCustomersAndSellers();
                    controller.selectedCustomersSellers.value = true;
                  },
                ),
              )
            ],
          ),
        ),
        if (controller.isEdit.value)
          SupTextAndDis(
            showLine: false,
            title: 'partnerName',
            discription: controller.partnershipName,
          ),
        if (controller.isEdit.value)
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 50.w),
            height: 1.h,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor3,
          ),
        SizedBox(height: 10.h),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: CustomDropdownFieldWithSearch(
                  tital:
                      //  controller.selectedCustomersSellers.value == false
                      //     ? 'customerName'.tr
                      //     :
                      'partnerName'.tr,
                  hint: 'customerNameExample',
                  items: controller.selectedCustomersSellers.value == false
                      ? controller.allCustomersList
                      : controller.allSellersList,
                  onChanged: (value) {
                    if (value != null) {
                      controller.partnerId.value = value.id.toString();
                    }
                  },
                  itemAsString: (item) => item.name,
                  compareFn: (a, b) => a.id == b.id,
                  validator: (value) => null,
                ),
              ),
              IconButton(
                onPressed: () =>
                    Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN, arguments: {
                  'sellerId': controller.partnerId.value,
                  'employeeId': controller.partnerId.value,
                  'employeeType': controller.selectedCustomersSellers.value
                      ? 'customer'
                      : 'seller',
                })?.then((value) => controller.getAllCustomersAndSellers()),
                icon: Icon(
                  Icons.add_circle_sharp,
                  color: AppColors.primaryColor,
                  size: 35.sp,
                ),
              )
            ],
          ),
        ),
        SizedBox(height: 15.h),
        CustomTextField(
          label: 'partnerShare',
          hintText: 'partnerShareExample',
          controller: controller.partnerShareController,
          keyboardType: TextInputType.number,
          validator: (value) => null,
        ),
        SizedBox(height: 15.h),
        Row(
          children: [
            Flexible(
              child: CustomTextField(
                label: 'partnerSharePercentage',
                hintText: 'partnerSharePercentageExample',
                controller: controller.partnerPercentageController,
                keyboardType: TextInputType.number,
                validator: (value) => null,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: CustomTextField(
                label: 'notes',
                hintText: 'projectNotesExample',
                controller: controller.notesController,
                validator: (value) => null,
              ),
            ),
          ],
        ),
        if (controller.isEdit.value) ShowImage(list: controller.paperImages),
        SizedBox(height: 20.h),
        // بيانات الشراكة
        MediaUploadButton(
          title: 'projectDocuments',
          allowedType: MediaType.image,
          onFilesChanged: (files) {
            for (var file in files) {
              if (!controller.paperImages.contains(file)) {
                controller.paperImages.add(file);
              }
            }
          },
        ),
      ],
    );
  }
}
