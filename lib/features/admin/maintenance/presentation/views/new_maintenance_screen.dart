import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/show_image_or_video.dart';
import '../../../../../core/helpers/showtime.dart';
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
                            value: RxBool(controller.selectedSellers.value),
                            onChanged: (val) {
                              controller.getAllCustomersAndSellers();
                              if (!controller.isEdit.value) {
                                controller.selectedSellers.value = true;
                                controller.partnerIdController.clear();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: CustomCheckBox(
                            title: 'customer'.tr,
                            value: RxBool(!controller.selectedSellers.value),
                            onChanged: (val) {
                              controller.getAllCustomersAndSellers();
                              if (!controller.isEdit.value) {
                                controller.selectedSellers.value = false;
                                controller.partnerIdController.clear();
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
                                      'popOnceOnSuccess': true,
                                      'employeeType':
                                          controller.selectedSellers.value
                                              ? 'seller'
                                              : 'customer',
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
                  _MaintenanceDeliveryDateTimeFields(controller: controller),
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

class _MaintenanceDeliveryDateTimeFields extends StatelessWidget {
  const _MaintenanceDeliveryDateTimeFields({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'deliveryDate'.tr,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.operationalNavy,
          ),
        ),
        SizedBox(height: 6.h),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _MaintenancePickerTile(
                  icon: Icons.calendar_today_outlined,
                  value: showData(controller.deliveryDate.value),
                  onTap: () => controller.pickDeliveryDate(context),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MaintenancePickerTile(
                  icon: Icons.access_time_rounded,
                  value: _formatTime(controller.deliveryTime.value),
                  onTap: () => controller.pickDeliveryTime(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _MaintenancePickerTile extends StatelessWidget {
  const _MaintenancePickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: AppColors.operationalPurple,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.operationalNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
