import 'dart:io';

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
import '../../../../../core/helpers/show_image_or_video.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
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
                  _MaintenanceMediaPicker(controller: controller),
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
                  if (!controller.isDelivered.value)
                    NextBackButton(
                      isLoading: controller.isLoading,
                      endTitle: 'delivered',
                      totalSteps: controller.timeLineSteps.length.obs,
                      selectedStep: controller.selectedStep,
                      onPressedBack: controller.prevStep,
                      onPressedNext: controller.nextStep,
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

class _MaintenanceMediaPicker extends StatelessWidget {
  const _MaintenanceMediaPicker({required this.controller});

  final MaintenanceController controller;

  Future<void> _capture() async {
    final result = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(),
    );
    if (result == null) return;

    final file = File(result.path);
    if (!controller.selectedMedia.any((item) => item.path == file.path)) {
      controller.selectedMedia.add(file);
      controller.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.selectedMedia.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: _capture,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primaryColor,
                size: 28.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                'uploadMedia'.tr,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 72.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.selectedMedia.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (_, index) {
          if (index == controller.selectedMedia.length) {
            return InkWell(
              borderRadius: BorderRadius.circular(6.r),
              onTap: _capture,
              child: Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.primaryColor,
                  size: 28.sp,
                ),
              ),
            );
          }

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
    );
  }
}
