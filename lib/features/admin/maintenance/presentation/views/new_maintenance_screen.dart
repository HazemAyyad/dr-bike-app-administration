import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_time_picker.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/show_image_or_video.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/custom_line_steps_widget.dart';
import '../widgets/maintenance_products_section.dart';
import '../widgets/next_back_button.dart';

class NewMaintenanceScreen extends StatelessWidget {
  const NewMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'createMaintenance',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: GetBuilder<MaintenanceController>(
          builder: (controller) {
            if (controller.isEditLoading.value) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 200.h),
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            return Form(
              key: controller.formKey,
              child: Column(
                children: [
                  CustomLineSteps(
                    timeLineSteps: controller.timeLineSteps,
                    selectedStep: controller.selectedStep,
                    changeSelected: controller.changeSelected,
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: CustomCheckBox(
                            title: 'seller'.tr,
                            value: RxBool(
                                !controller.selectedSellers.value == true),
                            onChanged: (val) {
                              controller.getAllCustomersAndSellers();
                              if (!controller.isEdit.value) {
                                controller.selectedSellers.value = false;
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: CustomCheckBox(
                            title: 'customer'.tr,
                            value: RxBool(
                                !controller.selectedSellers.value == false),
                            onChanged: (val) {
                              controller.getAllCustomersAndSellers();
                              if (!controller.isEdit.value) {
                                controller.selectedSellers.value = true;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: CustomDropdownFieldWithSearch(
                            value: controller.selectedSellers.value == false
                                ? controller.allCustomersList.firstWhereOrNull(
                                    (item) =>
                                        item.id.toString() ==
                                        controller.partnerIdController.text)
                                : controller.allSellersList.firstWhereOrNull(
                                    (item) =>
                                        item.id.toString() ==
                                        controller.partnerIdController.text),
                            isRequired: true,
                            tital: 'customerName'.tr,
                            hint: 'customerNameExample',
                            items: controller.selectedSellers.value == false
                                ? controller.allCustomersList
                                : controller.allSellersList,
                            onChanged: (value) {
                              if (value != null) {
                                controller.partnerIdController.text =
                                    value.id.toString();
                              }
                            },
                            isEnabled: !controller.isEdit.value,
                            itemAsString: (item) => item.name,
                            compareFn: (a, b) => a.id == b.id,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.isEdit.value
                              ? null
                              : () => Get.toNamed(
                                    AppRoutes.ADDNEWCUSTOMERSCREEN,
                                    arguments: {
                                      'sellerId': '',
                                      'employeeId': '',
                                      'employeeType':
                                          controller.selectedSellers.value
                                              ? 'customer'
                                              : 'seller',
                                    },
                                  )?.then((_) {
                                    controller.getAllCustomersAndSellers();
                                  }),
                          icon: Icon(
                            Icons.add_circle_sharp,
                            color: AppColors.primaryColor,
                            size: 30.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomCalendar(
                          isRequired: true,
                          label: 'deliveryDate',
                          isVisible: controller.isCalendarVisible,
                          onTap: () {
                            controller.isCalendarVisible.value =
                                !controller.isCalendarVisible.value;
                          },
                          selectedDay: controller.deliveryDate,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomTimePicker(
                          label: 'deliveryTime',
                          isRequired: true,
                          isVisible: controller.isTimeVisible,
                          onTap: () {
                            controller.isTimeVisible.value =
                                !controller.isTimeVisible.value;
                          },
                          selectedTime: controller.deliveryTime,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  CustomTextField(
                    validator: (value) => null,
                    label: 'details',
                    hintText: 'detailsExample',
                    controller: controller.descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                  SizedBox(height: 12.h),
                  MaintenanceProductsSection(controller: controller),
                  SizedBox(height: 10.h),
                  if (controller.selectedMedia.isNotEmpty)
                    SizedBox(
                      height: 72.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.selectedMedia.length,
                        separatorBuilder: (_, __) => SizedBox(width: 6.w),
                        itemBuilder: (_, index) {
                          final file = controller.selectedMedia[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6.r),
                                child: SizedBox(
                                  width: 72.w,
                                  height: 72.h,
                                  child: ShowImageOrVideo(path: file.path),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    controller.selectedMedia.removeAt(index);
                                    controller.update();
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  MediaUploadButton(
                    title: 'uploadMedia',
                    allowedType: MediaType.both,
                    isShowPreview: false,
                    onFilesChanged: (files) {
                      for (var file in files) {
                        if (!controller.selectedMedia
                            .any((f) => f.path == file.path)) {
                          controller.selectedMedia.add(file);
                        }
                      }
                      controller.update();
                    },
                  ),
                  SizedBox(height: 20.h),
                  if (!controller.isDelivered.value)
                    AppButton(
                      isLoading: controller.isLoading,
                      text: 'save',
                      onPressed: () {
                        controller.createMaintenance(
                          step: controller.selectedStep.value,
                          maintenanceId: controller.maintenanceId,
                          isSave: true,
                        );
                      },
                    ),
                  NextBackButton(
                    isLoading: controller.isLoading,
                    endTitle: 'delivered',
                    totalSteps: controller.timeLineSteps.length.obs,
                    selectedStep: controller.selectedStep,
                    onPressedBack: controller.prevStep,
                    onPressedNext: controller.isDelivered.value
                        ? () {}
                        : controller.nextStep,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
