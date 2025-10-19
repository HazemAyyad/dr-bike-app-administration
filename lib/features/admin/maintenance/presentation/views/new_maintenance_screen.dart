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
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: GetBuilder<MaintenanceController>(
          builder: (controller) {
            if (controller.isEditLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 250.h),
                    const Center(child: CircularProgressIndicator()),
                  ],
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
                  SizedBox(height: 20.h),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: CustomCheckBox(
                            title: 'seller'.tr,
                            value: RxBool(
                                !controller.selectedSellers.value == true),
                            onChanged: (val) {
                              controller.isEdit.value
                                  ? null
                                  : controller.selectedSellers.value = false;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomCheckBox(
                            title: 'customer'.tr,
                            value: RxBool(
                                !controller.selectedSellers.value == false),
                            onChanged: (val) {
                              controller.isEdit.value
                                  ? null
                                  : controller.selectedSellers.value = true;
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
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
                          onPressed: () => Get.toNamed(
                              AppRoutes.ADDNEWCUSTOMERSCREEN,
                              arguments: {
                                'sellerId': '',
                                'employeeId': '',
                                'employeeType': controller.selectedSellers.value
                                    ? 'customer'
                                    : 'seller',
                              }),
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
                  CustomCalendar(
                    isRequired: true,
                    label: 'deliveryDate',
                    isVisible: controller.isCalendarVisible,
                    onTap: () {
                      controller.isCalendarVisible.value =
                          !controller.isCalendarVisible.value;
                    },
                    selectedDay: controller.deliveryDate,
                  ),
                  SizedBox(height: 15.h),
                  CustomTimePicker(
                    label: 'deliveryTime',
                    isRequired: true,
                    isVisible: controller.isTimeVisible,
                    onTap: () {
                      controller.isTimeVisible.value =
                          !controller.isTimeVisible.value;
                    },
                    selectedTime: controller.deliveryTime,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextField(
                    validator: (value) => null,
                    label: 'details',
                    hintText: 'detailsExample',
                    controller: controller.descriptionController,
                    minLines: 6,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => controller.isLoading.value
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : controller.selectedMedia.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: EdgeInsets.only(top: 10.h),
                                  child: Row(
                                    children: [
                                      ...controller.selectedMedia
                                          .asMap()
                                          .entries
                                          .map(
                                        (entry) {
                                          final index = entry.key;
                                          final file = entry.value;
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5.w),
                                            child: Stack(
                                              children: [
                                                ShowImageOrVideo(
                                                  path: file.path,
                                                ),
                                                // زرار فوق الصورة
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      controller
                                                          .isLoading(true);
                                                      controller.selectedMedia
                                                          .removeAt(index);
                                                      controller
                                                          .isLoading(false);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MediaUploadButton(
                    title: 'uploadMedia',
                    allowedType: MediaType.both,
                    isShowPreview: false,
                    onFilesChanged: (files) {
                      if (controller.selectedMedia.isEmpty) {
                        controller.selectedMedia = files;
                      } else {
                        for (var file in files) {
                          if (!controller.selectedMedia
                              .any((f) => f.path == file.path)) {
                            controller.selectedMedia.add(file);
                          }
                        }
                      }
                      controller.update();
                    },
                  ),
                  SizedBox(height: 30.h),
                  if (controller.isEdit.value)
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
                    onPressedNext: controller.currentTab.value != 3
                        ? controller.nextStep
                        : () {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
      resizeToAvoidBottomInset: null,
    );
  }
}
