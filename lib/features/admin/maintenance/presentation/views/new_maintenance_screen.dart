import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_time_picker.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/video_view.dart';
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
                              controller.selectedSellers.value = false;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomCheckBox(
                            title: 'customer'.tr,
                            value: RxBool(
                                !controller.selectedSellers.value == false),
                            onChanged: (val) {
                              controller.selectedSellers.value = true;
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
                  ),
                  ...controller.selectedMedia.map(
                    (e) {
                      final isVideo = e.path.toLowerCase().endsWith('.mp4') ||
                          e.path.toLowerCase().endsWith('.mov') ||
                          e.path.toLowerCase().endsWith('.avi');

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 10.h),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5.r),
                          child: GestureDetector(
                            onTap: () {
                              if (isVideo) {
                                // عرض الفيديو في شاشة كاملة
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  barrierColor: Colors.black.withAlpha(128),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return VideoView(videoPath: e.path);
                                  },
                                );
                              } else {
                                // عرض الصورة في شاشة كاملة
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  barrierColor: Colors.black.withAlpha(128),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return FullScreenZoomImage(
                                        imageUrl: e.path);
                                  },
                                );
                              }
                            },
                            child: isVideo
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // صورة مصغرة للفيديو (thumbnail)
                                      Container(
                                        height: 200.h,
                                        width: 200.w,
                                        color: Colors.black12,
                                        child: const Icon(
                                          Icons.videocam,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ],
                                  )
                                : CachedNetworkImage(
                                    imageUrl: e.path,
                                    height: 200.h,
                                    width: 200.w,
                                    fit: BoxFit.fill,
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30.h),
                  MediaUploadButton(
                    title: 'uploadMedia',
                    allowedType: MediaType.both,
                    onFilesChanged: (files) {
                      if (files.isNotEmpty) controller.selectedMedia = files;
                    },
                  ),
                  SizedBox(height: 30.h),
                  NextBackButton(
                    isLoading: controller.isLoading,
                    endTitle: 'delivered',
                    totalSteps: controller.timeLineSteps.length.obs,
                    selectedStep: controller.selectedStep,
                    onPressedBack: controller.prevStep,
                    onPressedNext: controller.nextStep,
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
