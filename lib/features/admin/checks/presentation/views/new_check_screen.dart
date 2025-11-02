import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../controllers/checks_controller.dart';

class NewCheckScreen extends GetView<ChecksController> {
  const NewCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNewCheck = !controller.isInComing;

    return Scaffold(
      appBar: CustomAppBar(
          title: controller.isEdit.value
              ? 'editCheck'.tr
              : isNewCheck
                  ? 'newCheck'.tr
                  : 'newReceipt'.tr,
          action: false),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              CustomTextField(
                label: 'checkValue',
                hintText: 'totalExample',
                controller: controller.checkValueController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                isRequired: true,
                enabled: !controller.isEdit.value,
              ),
              SizedBox(height: isNewCheck ? 0 : 16.h),
              isNewCheck
                  ? const SizedBox()
                  : Column(
                      children: [
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'seller'.tr,
                                  value: RxBool(!controller
                                          .selectedCustomersSellers.value ==
                                      true),
                                  onChanged: (val) {
                                    controller.getAllCustomersAndSellers();
                                    if (controller.isEdit.value) {
                                      null;
                                    } else {
                                      controller.selectedValue.value = null;
                                      controller.selectedCustomersSellers
                                          .value = false;
                                    }
                                  },
                                ),
                              ),
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'customer'.tr,
                                  value: RxBool(!controller
                                          .selectedCustomersSellers.value ==
                                      false),
                                  onChanged: (val) {
                                    controller.getAllCustomersAndSellers();
                                    if (controller.isEdit.value) {
                                      null;
                                    } else {
                                      controller.selectedValue.value = null;
                                      controller.selectedCustomersSellers
                                          .value = true;
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: CustomDropdownFieldWithSearch(
                                  tital: 'beneficiaryName',
                                  hint: 'customerNameExample',
                                  items: controller
                                              .selectedCustomersSellers.value ==
                                          false
                                      ? controller.allCustomersList
                                      : controller.allSellersList,
                                  onChanged: (val) {
                                    controller.selectedValue.value =
                                        val!.id.toString();
                                  },
                                  itemAsString: (f) => f.name,
                                  compareFn: (a, b) => a.id == b.id,
                                  value: controller.selectedValue.value == null
                                      ? null
                                      : (!controller
                                              .selectedCustomersSellers.value
                                          ? controller.allCustomersList
                                              .firstWhereOrNull(
                                              (e) =>
                                                  e.id ==
                                                  int.tryParse(controller
                                                      .selectedValue.value!),
                                            )
                                          : controller.allSellersList
                                              .firstWhereOrNull(
                                              (e) =>
                                                  e.id ==
                                                  int.tryParse(controller
                                                      .selectedValue.value!),
                                            )),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Get.toNamed(
                                  AppRoutes.ADDNEWCUSTOMERSCREEN,
                                  arguments: {
                                    'employeeType': '',
                                    'employeeId': '',
                                    'sellerId': '',
                                  },
                                )?.then((value) {
                                  controller.getAllCustomersAndSellers();
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
                      ],
                    ),
              SizedBox(height: 16.h),
              CustomCalendar(
                isVisible: controller.isCalendarVisible,
                onTap: () => controller.toggleCalendar(),
                selectedDay: controller.selectedDay,
                label: 'due_date',
                isRequired: true,
              ),
              SizedBox(height: 16.h),
              CustomDropdownField(
                isRequired: true,
                label: 'currencyy',
                hint: 'currencyExample',
                items: controller.currency,
                onChanged: (value) {
                  controller.currencyController.text = value!;
                },
                value: controller.currencyController.text.isEmpty
                    ? null
                    : controller.currencyController.text,
                isEnabled: !controller.isEdit.value,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'checkNumber',
                hintText: 'checkNumberExample',
                controller: controller.checkNumberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                isRequired: true,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'bankName',
                hintText: 'bankNameExample',
                controller: controller.bankNameController,
                textInputAction: TextInputAction.next,
                isRequired: true,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'notes',
                hintText: 'notes',
                controller: controller.notesController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 5,
                validator: (p0) => null,
              ),
              SizedBox(height: 20.h),
              if (controller.editCheckBackImage.value == null)
                SizedBox(height: 20.h),
              if (controller.editCheckFrontImage.value != null &&
                  controller.isEdit.value)
                Column(
                  children: [
                    const SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'checkFrontImage',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.editCheckFrontImage.value !=
                                    null) {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: 'Dismiss',
                                    barrierColor: Colors.black.withAlpha(128),
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                    pageBuilder: (context, anim1, anim2) {
                                      return FullScreenZoomImage(
                                        imageUrl: controller
                                            .editCheckFrontImage.value!.path,
                                      );
                                    },
                                  );
                                }
                              },
                              child: Obx(() {
                                final img =
                                    controller.editCheckFrontImage.value;
                                if (img == null) {
                                  // لو ما في صورة — تعرض عنصر بديل أو مكان الاحتياطي
                                  return Container(
                                    height: 300.h,
                                    width: 300.w,
                                    color: Colors.grey[300],
                                    child: const Center(
                                        child: Text("لا توجد صورة")),
                                  );
                                }
                                return CachedNetworkImage(
                                  cacheManager: CacheManager(
                                    Config(
                                      'paperImagesCache',
                                      stalePeriod: const Duration(days: 7),
                                      maxNrOfCacheObjects: 100,
                                    ),
                                  ),
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    height: 300.h,
                                    width: 300.w,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  imageUrl: img.path,
                                  placeholder: (context, url) => SizedBox(
                                    height: 300.h,
                                    width: 300.w,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                );
                              }),
                            ),
                            // زر الحذف
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Obx(() {
                                final img =
                                    controller.editCheckFrontImage.value;
                                if (img == null) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    // تنفيذ حذف الصورة من الحالة
                                    controller.editCheckFrontImage.value = null;
                                    controller.checkFrontImage.value = null;
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 35,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              UploadImageButton(
                selectedFile: controller.checkFrontImage,
                title: 'checkFrontImage',
              ),
              SizedBox(height: 20.h),
              if (controller.editCheckBackImage.value == null)
                SizedBox(height: 20.h),
              if (controller.editCheckBackImage.value != null &&
                  controller.isEdit.value &&
                  controller.isInComing)
                Column(
                  children: [
                    const SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'checkBackImage',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final img = controller.editCheckBackImage.value;
                                if (img != null) {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: 'Dismiss',
                                    barrierColor: Colors.black.withAlpha(128),
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                    pageBuilder: (context, anim1, anim2) {
                                      return FullScreenZoomImage(
                                        imageUrl: img.path,
                                      );
                                    },
                                  );
                                }
                              },
                              child: Obx(() {
                                final img = controller.editCheckBackImage.value;
                                if (img == null) {
                                  // لو ما في صورة خلفية — تعرض مساحة بديلة
                                  return Container(
                                    height: 300.h,
                                    width: 300.w,
                                    color: Colors.grey[300],
                                    child: const Center(
                                        child: Text("لا توجد صورة خلفية")),
                                  );
                                }
                                return CachedNetworkImage(
                                  cacheManager: CacheManager(
                                    Config(
                                      'imagesCache',
                                      stalePeriod: const Duration(days: 7),
                                      maxNrOfCacheObjects: 100,
                                    ),
                                  ),
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    height: 300.h,
                                    width: 300.w,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  imageUrl: img.path,
                                  placeholder: (context, url) => SizedBox(
                                    height: 300.h,
                                    width: 300.w,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                );
                              }),
                            ),
                            // زر الحذف للخلفية
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Obx(() {
                                final img = controller.editCheckBackImage.value;
                                if (img == null) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    // حذف الصورة الخلفية من الحالة
                                    controller.editCheckBackImage.value = null;
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 35,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              isNewCheck
                  ? const SizedBox()
                  : UploadImageButton(
                      selectedFile: controller.checkBackImage,
                      title: 'checkBackImage',
                    ),
              SizedBox(height: isNewCheck ? 0 : 50.h),
              AppButton(
                isLoading: controller.isLoading,
                text: controller.isEdit.value
                    ? 'editCheck'.tr
                    : isNewCheck
                        ? 'createCheck'.tr
                        : 'cashTheChecks'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.w700,
                    ),
                onPressed: () {
                  controller.isEdit.value
                      ? controller.editChecks(
                          context: context,
                          isInComing: !isNewCheck,
                          checkId: controller.checkId!,
                        )
                      : controller.addChecks(
                          isInComing: !isNewCheck,
                          context: context,
                          customerId: !isNewCheck &&
                                  !controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                          sellerId: !isNewCheck &&
                                  controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
