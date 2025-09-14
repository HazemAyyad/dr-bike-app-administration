import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../controllers/project_controller.dart';

class FirstStep extends GetView<ProjectController> {
  const FirstStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
                label: 'projectCost',
                hintText: 'projectCostExample',
                controller: controller.projectCostController,
                keyboardType: TextInputType.number,
                validator: (value) => null,
              ),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        CustomDropdownFieldWithSearch(
          label: 'productName'.tr,
          hint: 'itemExample',
          items: controller.products,
          onChanged: (value) {
            if (value != null) {
              controller.itemIdController.text = value.id.toString();
            }
          },
          itemAsString: (u) => u.nameAr,
          compareFn: (a, b) => a.id == b.id,
          validator: (value) => null,
        ),
        SizedBox(height: 20.h),
        MediaUploadButton(
          title: 'projectOrProductsImages',
          allowedType: MediaType.image,
          onFilesChanged: (files) {
            controller.projectImages = files;
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
                    // controller.selectedValue.value = '';
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
                    // controller.selectedValue.value = '';
                    controller.selectedCustomersSellers.value = true;
                  },
                ),
              )
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => CustomDropdownFieldWithSearch(
            label:
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
        SizedBox(height: 20.h),
        // بيانات الشراكة
        MediaUploadButton(
          title: 'projectDocuments',
          allowedType: MediaType.image,
          onFilesChanged: (files) {
            controller.paperImages = files;
          },
        ),
      ],
    );
  }
}
