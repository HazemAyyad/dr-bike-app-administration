import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/bank_name_field.dart';
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
    try {
      return _buildScreen(context);
    } catch (e, st) {
      debugPrint('[NewCheckScreen] build failed: $e\n$st');
      return Scaffold(
        appBar: CustomAppBar(title: 'newReceipt'.tr, action: false),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildScreen(BuildContext context) {
    final args = Get.arguments;
    final bool? isNewCheckArg =
        args is Map ? args['isNewCheck'] as bool? : null;
    if (isNewCheckArg != null) {
      controller.isInComing = !isNewCheckArg;
    }
    final bool isNewCheck = isNewCheckArg ?? !controller.isInComing;
    final bool isIncomingBatch = !isNewCheck && !controller.isEdit.value;
    if (isIncomingBatch) {
      return _IncomingBatchCreateScaffold(controller: controller);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: CustomAppBar(
          title: controller.isEdit.value
              ? 'editCheck'.tr
              : isNewCheck
                  ? 'newCheck'.tr
                  : 'newReceipt'.tr,
          action: false),
      bottomNavigationBar: isIncomingBatch
          ? _SaveIncomingBatchButton(controller: controller)
          : null,
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.w,
            12.h,
            16.w,
            isIncomingBatch ? 110.h : 0,
          ),
          child: Column(
            children: [
              if (isIncomingBatch) ...[
                _IncomingBatchHeader(
                  title: 'newReceipt'.tr,
                  subtitle: 'batchSummary'.tr,
                ),
                SizedBox(height: 14.h),
              ],
              Builder(builder: (context) {
                return const SizedBox.shrink();
              }),
              _InputPanel(
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'checkValue',
                      hintText: 'totalExample',
                      controller: controller.checkValueController,
                      focusNode: controller.checkValueFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      enabled: !controller.isEdit.value,
                      fillColor: Colors.white,
                      onFieldSubmitted: (_) =>
                          controller.bankNameFocus.requestFocus(),
                    ),
                    SizedBox(height: isNewCheck ? 0 : 16.h),
                    if (!isNewCheck)
                      Column(
                        children: [
                          Builder(builder: (context) {
                            return const SizedBox.shrink();
                          }),
                          Obx(
                            () => _PersonTypeSelector(
                              isCustomer:
                                  controller.selectedCustomersSellers.value,
                              enabled: !controller.isEdit.value,
                              onChanged: (isCustomer) {
                                controller.getAllCustomersAndSellers();
                                if (controller.isEdit.value) return;
                                controller.selectedValue.value = null;
                                controller.selectedCustomersSellers.value =
                                    isCustomer;
                              },
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
                                            .selectedCustomersSellers.value
                                        ? controller.allCustomersList
                                        : controller.allSellersList,
                                    onChanged: (val) {
                                      controller.selectedValue.value =
                                          val!.id.toString();
                                    },
                                    itemAsString: (f) => f.name,
                                    compareFn: (a, b) => a.id == b.id,
                                    value:
                                        controller.selectedValue.value == null
                                            ? null
                                            : (!controller
                                                    .selectedCustomersSellers
                                                    .value
                                                ? controller.allSellersList
                                                    .firstWhereOrNull(
                                                    (e) =>
                                                        e.id ==
                                                        int.tryParse(controller
                                                            .selectedValue
                                                            .value!),
                                                  )
                                                : controller.allCustomersList
                                                    .firstWhereOrNull(
                                                    (e) =>
                                                        e.id ==
                                                        int.tryParse(controller
                                                            .selectedValue
                                                            .value!),
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
                    if (isIncomingBatch) ...[
                      Builder(builder: (context) {
                        return const SizedBox.shrink();
                      }),
                      SizedBox(height: 16.h),
                      CustomCalendar(
                        isVisible: controller.isReceivedCalendarVisible,
                        onTap: () => controller.toggleReceivedCalendar(),
                        selectedDay: controller.receivedDay,
                        label: 'receivedDate',
                        isRequired: true,
                      ),
                      SizedBox(height: 16.h),
                      CustomTextField(
                        label: 'numberOfChecks',
                        hintText: 'numberOfChecks',
                        controller: controller.incomingBatchCountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => controller.update(),
                        isRequired: true,
                        fillColor: Colors.white,
                      ),
                    ],
                    SizedBox(height: 16.h),
                    Builder(builder: (context) {
                      return const SizedBox.shrink();
                    }),
                    CustomCalendar(
                      isVisible: controller.isCalendarVisible,
                      onTap: () => controller.toggleCalendar(),
                      selectedDay: controller.selectedDay,
                      label: isIncomingBatch ? 'firstDueDate' : 'due_date',
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
                    BankNameField(
                      controller: controller.bankNameController,
                      focusNode: controller.bankNameFocus,
                      onSubmitted: () =>
                          controller.checkNumberFocus.requestFocus(),
                    ),
                    if (!isIncomingBatch) ...[
                      SizedBox(height: 16.h),
                      CustomTextField(
                        label: 'checkNumber',
                        hintText: 'checkNumberExample',
                        controller: controller.checkNumberController,
                        focusNode: controller.checkNumberFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        isRequired: true,
                        fillColor: Colors.white,
                        onFieldSubmitted: (_) =>
                            controller.notesFocus.requestFocus(),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    CustomTextField(
                      label: 'notes',
                      hintText: 'notes',
                      controller: controller.notesController,
                      focusNode: controller.notesFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 5,
                      fillColor: Colors.white,
                      validator: (p0) => null,
                      onFieldSubmitted: (_) async {
                        FocusScope.of(context).unfocus();
                        await UploadImageButton.pickFileFor(
                          context,
                          controller.checkFrontImage,
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (isIncomingBatch) ...[
                Builder(builder: (context) {
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 16.h),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.incomingBatchCountController,
                  builder: (context, value, _) {
                    final count = int.tryParse(value.text.trim()) ?? 0;
                    return AppButton(
                      isLoading: false.obs,
                      text: count == 1
                          ? 'prepareSingleCheck'
                          : 'generateChecksRows',
                      textStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.whiteColor,
                                fontWeight: FontWeight.w700,
                              ),
                      onPressed: controller.generateIncomingBatchRows,
                    );
                  },
                ),
                SizedBox(height: 16.h),
                _IncomingBatchSummary(controller: controller),
                SizedBox(height: 12.h),
                _IncomingBatchRows(controller: controller),
              ],
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
              if (!isIncomingBatch)
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
              isNewCheck || isIncomingBatch
                  ? const SizedBox()
                  : UploadImageButton(
                      selectedFile: controller.checkBackImage,
                      title: 'checkBackImage',
                    ),
              SizedBox(height: isNewCheck ? 0 : 50.h),
              if (!isIncomingBatch)
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
                                    controller.selectedCustomersSellers.value
                                ? controller.selectedValue.value
                                : null,
                            sellerId: !isNewCheck &&
                                    !controller.selectedCustomersSellers.value
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

class _IncomingBatchHeader extends StatelessWidget {
  const _IncomingBatchHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 72.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: const Color(0xFF166534),
              size: 21.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingBatchCreateScaffold extends StatelessWidget {
  const _IncomingBatchCreateScaffold({required this.controller});

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('newReceipt'.tr),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
          children: [
            _IncomingBatchHeader(
              title: 'newReceipt'.tr,
              subtitle: 'batchSummary'.tr,
            ),
            SizedBox(height: 12.h),
            _InputPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlainTextField(
                    label: 'checkValue'.tr,
                    hint: 'totalExample'.tr,
                    controller: controller.checkValueController,
                    keyboardType: TextInputType.number,
                    requiredField: true,
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => _PersonTypeSelector(
                      isCustomer: controller.selectedCustomersSellers.value,
                      enabled: !controller.isEdit.value,
                      onChanged: (isCustomer) {
                        controller.getAllCustomersAndSellers();
                        controller.selectedValue.value = null;
                        controller.selectedCustomersSellers.value = isCustomer;
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                    final people = controller.selectedCustomersSellers.value
                        ? controller.allCustomersList
                        : controller.allSellersList;
                    return CustomDropdownFieldWithSearch(
                      tital: 'beneficiaryName',
                      hint: 'customerNameExample',
                      items: people,
                      onChanged: (val) {
                        controller.selectedValue.value = val!.id.toString();
                      },
                      itemAsString: (f) => f.name,
                      compareFn: (a, b) => a.id == b.id,
                      value: controller.selectedValue.value == null
                          ? null
                          : people.firstWhereOrNull(
                              (e) =>
                                  e.id ==
                                  int.tryParse(
                                    controller.selectedValue.value!,
                                  ),
                            ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _DateTile(
                            label: 'receivedDate'.tr,
                            value: controller.receivedDay.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.receivedDay.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                controller.receivedDay.value = picked;
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Obx(
                          () => _DateTile(
                            label: 'firstDueDate'.tr,
                            value: controller.selectedDay.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.selectedDay.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                controller.selectedDay.value = picked;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PlainTextField(
                          label: 'numberOfChecks'.tr,
                          hint: 'numberOfChecks'.tr,
                          controller: controller.incomingBatchCountController,
                          keyboardType: TextInputType.number,
                          requiredField: true,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              controller.currencyController.text.isEmpty
                                  ? null
                                  : controller.currencyController.text,
                          isExpanded: true,
                          decoration: _plainInputDecoration('currencyy'.tr),
                          items: controller.currency
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item.tr),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.currencyController.text = value;
                            }
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'currencyy'.tr
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  BankNameField(
                    controller: controller.bankNameController,
                    focusNode: controller.bankNameFocus,
                    onSubmitted: () => controller.notesFocus.requestFocus(),
                  ),
                  SizedBox(height: 12.h),
                  _PlainTextField(
                    label: 'notes'.tr,
                    hint: 'notes'.tr,
                    controller: controller.notesController,
                    minLines: 3,
                    maxLines: 4,
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.generateIncomingBatchRows,
                      icon: const Icon(Icons.playlist_add),
                      label: ValueListenableBuilder<TextEditingValue>(
                        valueListenable:
                            controller.incomingBatchCountController,
                        builder: (context, value, _) {
                          final count = int.tryParse(value.text.trim()) ?? 0;
                          return Text(
                            (count == 1
                                    ? 'prepareSingleCheck'
                                    : 'generateChecksRows')
                                .tr,
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _IncomingBatchSummary(controller: controller),
            SizedBox(height: 12.h),
            _IncomingBatchRows(controller: controller),
            SizedBox(height: 12.h),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        controller.addIncomingChecksBatch(
                          context: context,
                          customerId: controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                          sellerId: !controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('saveChecksBatch'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.requiredField = false,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool requiredField;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: _plainInputDecoration(label).copyWith(hintText: hint),
      validator: requiredField
          ? (value) => value == null || value.trim().isEmpty ? label : null
          : null,
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _plainInputDecoration(label),
        child: Row(
          children: [
            Expanded(child: Text(DateFormat('yyyy/MM/dd').format(value))),
            Icon(Icons.calendar_today_outlined, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

InputDecoration _plainInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.4),
    ),
  );
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PersonTypeSelector extends StatelessWidget {
  const _PersonTypeSelector({
    required this.isCustomer,
    required this.enabled,
    required this.onChanged,
  });

  final bool isCustomer;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: false,
          label: Text('seller'.tr),
          icon: const Icon(Icons.storefront_outlined),
        ),
        ButtonSegment(
          value: true,
          label: Text('customer'.tr),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      selected: {isCustomer},
      onSelectionChanged: enabled ? (value) => onChanged(value.first) : null,
    );
  }
}

class _SaveIncomingBatchButton extends StatelessWidget {
  const _SaveIncomingBatchButton({required this.controller});

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: AppButton(
        isLoading: controller.isLoading,
        isSafeArea: false,
        text: 'saveChecksBatch',
        textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16.sp,
              color: AppColors.whiteColor,
              fontWeight: FontWeight.w700,
            ),
        onPressed: () {
          controller.addIncomingChecksBatch(
            context: context,
            customerId: controller.selectedCustomersSellers.value
                ? controller.selectedValue.value
                : null,
            sellerId: !controller.selectedCustomersSellers.value
                ? controller.selectedValue.value
                : null,
          );
        },
      ),
    );
  }
}

class _IncomingBatchSummary extends StatelessWidget {
  const _IncomingBatchSummary({required this.controller});

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.incomingBatchRows;
      if (rows.isEmpty) return const SizedBox.shrink();
      final firstDue = rows.first.dueDate.value;
      final lastDue = rows.last.dueDate.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'batchSummary'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: [
                _SummaryChip(
                  icon: Icons.receipt_long,
                  text: '${'numberOfChecks'.tr}: ${rows.length}',
                ),
                _SummaryChip(
                  icon: Icons.event_available,
                  text:
                      '${'receivedDate'.tr}: ${DateFormat('yyyy/MM/dd').format(controller.receivedDay.value)}',
                ),
                _SummaryChip(
                  icon: Icons.date_range,
                  text:
                      '${'firstDueDate'.tr}: ${DateFormat('yyyy/MM/dd').format(firstDue)}',
                ),
                _SummaryChip(
                  icon: Icons.event,
                  text:
                      '${'lastDueDate'.tr}: ${DateFormat('yyyy/MM/dd').format(lastDue)}',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF166534)),
          SizedBox(width: 6.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 230.w),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF374151),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingBatchRows extends StatelessWidget {
  const _IncomingBatchRows({required this.controller});

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    final currencies = controller.currency.map((e) => e.tr).toList();

    return Obx(() {
      final rows = controller.incomingBatchRows;
      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: Card(
              margin: EdgeInsets.only(bottom: 12.h),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: ExpansionTile(
                tilePadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                initiallyExpanded: index == 0,
                title: Text(
                  '${'check'.tr} ${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _RowMeta(
                          text: row.total.text.isEmpty ? '-' : row.total.text),
                      Obx(
                        () => _RowMeta(
                          text: DateFormat('yyyy/MM/dd')
                              .format(row.dueDate.value),
                        ),
                      ),
                      Obx(() => _RowMeta(text: row.currency.value)),
                    ],
                  ),
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'checkValue',
                        hintText: 'totalExample',
                        controller: row.total,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ),
                      SizedBox(height: 12.h),
                      Obx(
                        () => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: row.dueDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) row.dueDate.value = picked;
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'due_date'.tr,
                              suffixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              DateFormat('yyyy/MM/dd')
                                  .format(row.dueDate.value),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: currencies.contains(row.currency.value)
                              ? row.currency.value
                              : null,
                          decoration:
                              InputDecoration(labelText: 'currencyy'.tr),
                          items: currencies
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) row.currency.value = value;
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'currencyy'.tr
                              : null,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        label: 'bankName',
                        hintText: 'bankNameExample',
                        controller: row.bankName,
                        isRequired: true,
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        label: 'checkNumber',
                        hintText: 'checkNumberExample',
                        controller: row.checkId,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ),
                      SizedBox(height: 12.h),
                      CustomTextField(
                        label: 'notes',
                        hintText: 'notes',
                        controller: row.notes,
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: 3,
                        validator: (_) => null,
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniImagePicker(
                              title: 'checkFrontImage',
                              selectedFile: row.frontImage,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _MiniImagePicker(
                              title: 'checkBackImage',
                              selectedFile: row.backImage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      );
    });
  }
}

class _RowMeta extends StatelessWidget {
  const _RowMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11.sp,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MiniImagePicker extends StatelessWidget {
  const _MiniImagePicker({
    required this.title,
    required this.selectedFile,
  });

  final String title;
  final Rx<XFile?> selectedFile;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: () async {
          await UploadImageButton.pickFileFor(context, selectedFile);
        },
        icon: Icon(
          selectedFile.value == null ? Icons.add_a_photo : Icons.check_circle,
        ),
        label: Text(
          title.tr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
