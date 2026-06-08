import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
import '../../../../../core/helpers/scroll_date_picker_sheet.dart';
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
    final bool isEditMode = (args is Map && args['isEdit'] == true) ||
        controller.isEdit.value;
    if (isEditMode) {
      controller.isEdit.value = true;
      return _CompactEditCheckScaffold(
        controller: controller,
        isOutgoing: isNewCheck,
      );
    }
    final bool isIncomingBatch = !isNewCheck && !controller.isEdit.value;
    if (isIncomingBatch) {
      return _IncomingBatchCreateScaffold(controller: controller);
    }
    if (isNewCheck) {
      return _CompactOutgoingCreateScaffold(controller: controller);
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

/// تعديل شيك — نفس بنية [_IncomingBatchCreateScaffold] (مجرّبة وتعمل).
class _CompactEditCheckScaffold extends StatefulWidget {
  const _CompactEditCheckScaffold({
    required this.controller,
    required this.isOutgoing,
  });

  final ChecksController controller;
  final bool isOutgoing;

  @override
  State<_CompactEditCheckScaffold> createState() =>
      _CompactEditCheckScaffoldState();
}

class _CompactEditCheckScaffoldState extends State<_CompactEditCheckScaffold> {
  ChecksController get c => widget.controller;

  static const double _imgH = 68;

  Widget _compactAddImageTile({
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: _imgH.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryColor.withAlpha(100),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 3.h),
              Text(
                'add'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('editCheck'.tr),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: c.formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
          children: [
            if (!widget.isOutgoing) ...[
              _buildSummary(context),
              SizedBox(height: 10.h),
            ],
            _InputPanel(
              child: widget.isOutgoing
                  ? _buildOutgoingEditFields(context)
                  : _buildIncomingEditFields(context),
            ),
            SizedBox(height: 10.h),
            _InputPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildImageSlot(
                      context,
                      title: 'checkFrontImage',
                      picked: c.checkFrontImage,
                      existing: c.editCheckFrontImage,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildImageSlot(
                      context,
                      title: 'checkBackImage',
                      picked: c.checkBackImage,
                      existing: c.editCheckBackImage,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: c.isLoading.value
                      ? null
                      : () {
                          c.editChecks(
                            context: context,
                            isInComing: !widget.isOutgoing,
                            checkId: c.checkId!,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: c.isLoading.value
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('editCheck'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingEditFields(BuildContext context) {
    return _OutgoingCheckFormFields(
      controller: c,
      onDateChanged: () => setState(() {}),
    );
  }

  Widget _buildIncomingEditFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoFieldRow(
          first: _DateTile(
            label: 'due_date'.tr,
            value: c.selectedDay.value,
            onChanged: (picked) {
              c.selectedDay.value = picked;
              setState(() {});
            },
          ),
          second: _PlainTextField(
            label: 'checkNumber'.tr,
            hint: 'checkNumberExample'.tr,
            controller: c.checkNumberController,
            keyboardType: TextInputType.number,
            requiredField: true,
          ),
        ),
        SizedBox(height: 10.h),
        BankNameField(
          plainStyle: true,
          controller: c.bankNameController,
          focusNode: c.bankNameFocus,
          onSubmitted: () => c.checkNumberFocus.requestFocus(),
        ),
        SizedBox(height: 10.h),
        _PlainTextField(
          label: 'notes'.tr,
          hint: 'notes'.tr,
          controller: c.notesController,
          minLines: 2,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final beneficiary = c.editBeneficiaryName;
    final personLabel = c.editBeneficiaryIsCustomer
        ? 'customer'.tr
        : 'seller'.tr;
    final currency = c.currencyController.text;

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
            'details'.tr,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _RowMeta(
                text: '${'checkValue'.tr}: ${c.checkValueController.text}',
              ),
              if (currency.isNotEmpty)
                _RowMeta(
                  text: '${'currencyy'.tr}: ${currency.tr}',
                ),
              if (beneficiary.isNotEmpty)
                _RowMeta(text: '$personLabel: $beneficiary'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlot(
    BuildContext context, {
    required String title,
    required Rx<XFile?> picked,
    required Rx<XFile?> existing,
  }) {
    final local = picked.value;
    final remote = existing.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF6B7280)),
        ),
        SizedBox(height: 4.h),
        if (local != null && !local.path.startsWith('http'))
          _imagePreview(
            context,
            child: Image.file(
              File(local.path),
              height: _imgH.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            onDelete: () {
              picked.value = null;
              setState(() {});
            },
          )
        else if (remote != null)
          _imagePreview(
            context,
            child: GestureDetector(
              onTap: () => _zoomImage(context, remote.path),
              child: CachedNetworkImage(
                imageUrl: remote.path,
                height: _imgH.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  height: _imgH.h,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => SizedBox(
                  height: _imgH.h,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            onDelete: () {
              existing.value = null;
              picked.value = null;
              setState(() {});
            },
          )
        else
          _compactAddImageTile(
            onTap: () async {
              await UploadImageButton.pickFileFor(context, picked);
              setState(() {});
            },
          ),
      ],
    );
  }

  Widget _imagePreview(
    BuildContext context, {
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
        Positioned(
          top: 3,
          right: 3,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 14.sp),
            ),
          ),
        ),
      ],
    );
  }

  void _zoomImage(BuildContext context, String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(128),
      pageBuilder: (_, __, ___) => FullScreenZoomImage(imageUrl: url),
    );
  }
}

/// إضافة شيك صادر — نفس ستايل [_CompactEditCheckScaffold] مع كل الحقول قابلة للإدخال.
class _CompactOutgoingCreateScaffold extends StatefulWidget {
  const _CompactOutgoingCreateScaffold({required this.controller});

  final ChecksController controller;

  @override
  State<_CompactOutgoingCreateScaffold> createState() =>
      _CompactOutgoingCreateScaffoldState();
}

class _CompactOutgoingCreateScaffoldState
    extends State<_CompactOutgoingCreateScaffold> {
  ChecksController get c => widget.controller;

  static const double _imgH = 68;

  Widget _compactAddImageTile({required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: _imgH.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryColor.withAlpha(100),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 3.h),
              Text(
                'add'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlot(
    BuildContext context, {
    required String title,
    required Rx<XFile?> picked,
  }) {
    final local = picked.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF6B7280)),
        ),
        SizedBox(height: 4.h),
        if (local != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(local.path),
                  height: _imgH.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: GestureDetector(
                  onTap: () {
                    picked.value = null;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                  ),
                ),
              ),
            ],
          )
        else
          _compactAddImageTile(
            onTap: () async {
              await UploadImageButton.pickFileFor(context, picked);
              setState(() {});
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('newCheck'.tr),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: c.formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
          children: [
            _InputPanel(
              child: _OutgoingCheckFormFields(
                controller: c,
                onDateChanged: () => setState(() {}),
              ),
            ),
            SizedBox(height: 10.h),
            _InputPanel(
              child: _buildImageSlot(
                context,
                title: 'checkFrontImage',
                picked: c.checkFrontImage,
              ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: c.isLoading.value
                      ? null
                      : () {
                          c.addChecks(
                            context: context,
                            isInComing: false,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: c.isLoading.value
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('createCheck'.tr),
                ),
              ),
            ),
          ],
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
              color: AppColors.primaryColor,
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
            _InputPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _PlainTextField(
                          label: 'checkValue'.tr,
                          hint: 'totalExample'.tr,
                          controller: controller.checkValueController,
                          keyboardType: TextInputType.number,
                          requiredField: true,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        flex: 2,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(
                          () => _CompactPersonTypeSelector(
                            isCustomer:
                                controller.selectedCustomersSellers.value,
                            enabled: !controller.isEdit.value,
                            onChanged: (isCustomer) {
                              controller.getAllCustomersAndSellers();
                              controller.selectedValue.value = null;
                              controller.selectedCustomersSellers.value =
                                  isCustomer;
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        flex: 3,
                        child: Obx(() {
                          final people =
                              controller.selectedCustomersSellers.value
                                  ? controller.allCustomersList
                                  : controller.allSellersList;
                          return _PlainBeneficiaryDropdown(
                            items: people,
                            value: controller.selectedValue.value == null
                                ? null
                                : people.firstWhereOrNull(
                                    (e) =>
                                        e.id ==
                                        int.tryParse(
                                          controller.selectedValue.value!,
                                        ),
                                  ),
                            onChanged: (val) {
                              controller.selectedValue.value =
                                  val!.id.toString();
                            },
                            itemAsString: (f) => f.name,
                            compareFn: (a, b) => a.id == b.id,
                          );
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _DateTile(
                            label: 'receivedDate'.tr,
                            value: controller.receivedDay.value,
                            onChanged: (picked) {
                              controller.receivedDay.value = picked;
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
                            onChanged: (picked) {
                              controller.selectedDay.value = picked;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _PlainTextField(
                    label: 'numberOfChecks'.tr,
                    hint: 'numberOfChecks'.tr,
                    controller: controller.incomingBatchCountController,
                    keyboardType: TextInputType.number,
                    requiredField: true,
                  ),
                  SizedBox(height: 12.h),
                  BankNameField(
                    plainStyle: true,
                    controller: controller.bankNameController,
                    focusNode: controller.bankNameFocus,
                    onSubmitted: () =>
                        controller.checkNumberFocus.requestFocus(),
                  ),
                  SizedBox(height: 12.h),
                  _PlainTextField(
                    label: 'checkNumber'.tr,
                    hint: 'checkNumberExample'.tr,
                    controller: controller.checkNumberController,
                    keyboardType: TextInputType.number,
                    requiredField: true,
                  ),
                  SizedBox(height: 12.h),
                  _PlainTextField(
                    label: 'notes'.tr,
                    hint: 'notes'.tr,
                    controller: controller.notesController,
                    minLines: 2,
                    maxLines: 3,
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
                  backgroundColor: AppColors.primaryColor,
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
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await ScrollDatePickerSheet.show(
      context,
      initial: value,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
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

Widget _twoFieldRow({
  required Widget first,
  required Widget second,
  int firstFlex = 1,
  int secondFlex = 1,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: firstFlex, child: first),
      SizedBox(width: 10.w),
      Expanded(flex: secondFlex, child: second),
    ],
  );
}

class _OutgoingCheckFormFields extends StatelessWidget {
  const _OutgoingCheckFormFields({
    required this.controller,
    this.onDateChanged,
  });

  final ChecksController controller;
  final VoidCallback? onDateChanged;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoFieldRow(
          firstFlex: 3,
          secondFlex: 2,
          first: _PlainTextField(
            label: 'checkValue'.tr,
            hint: 'totalExample'.tr,
            controller: c.checkValueController,
            keyboardType: TextInputType.number,
            requiredField: true,
          ),
          second: DropdownButtonFormField<String>(
            initialValue: c.currencyController.text.isEmpty
                ? null
                : c.currencyController.text,
            isExpanded: true,
            decoration: _plainInputDecoration('currencyy'.tr),
            items: c.currency
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item.tr),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                c.currencyController.text = value;
              }
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'currencyy'.tr : null,
          ),
        ),
        SizedBox(height: 10.h),
        _twoFieldRow(
          first: _DateTile(
            label: 'due_date'.tr,
            value: c.selectedDay.value,
            onChanged: (picked) {
              c.selectedDay.value = picked;
              onDateChanged?.call();
            },
          ),
          second: _PlainTextField(
            label: 'checkNumber'.tr,
            hint: 'checkNumberExample'.tr,
            controller: c.checkNumberController,
            keyboardType: TextInputType.number,
            requiredField: true,
          ),
        ),
        SizedBox(height: 10.h),
        BankNameField(
          plainStyle: true,
          controller: c.bankNameController,
          focusNode: c.bankNameFocus,
          onSubmitted: () => c.checkNumberFocus.requestFocus(),
        ),
        SizedBox(height: 10.h),
        _PlainTextField(
          label: 'notes'.tr,
          hint: 'notes'.tr,
          controller: c.notesController,
          minLines: 2,
          maxLines: 3,
        ),
      ],
    );
  }
}

InputDecoration _plainInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
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

class _CompactPersonTypeSelector extends StatelessWidget {
  const _CompactPersonTypeSelector({
    required this.isCustomer,
    required this.enabled,
    required this.onChanged,
  });

  final bool isCustomer;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _plainInputDecoration('beneficiaryType'.tr),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0),
          selectedBackgroundColor: AppColors.primaryColor.withAlpha(38),
          selectedForegroundColor: AppColors.primaryColor,
        ),
        segments: [
          ButtonSegment(
            value: false,
            label: Text('seller'.tr, style: TextStyle(fontSize: 11.sp)),
          ),
          ButtonSegment(
            value: true,
            label: Text('customer'.tr, style: TextStyle(fontSize: 11.sp)),
          ),
        ],
        selected: {isCustomer},
        onSelectionChanged: enabled ? (value) => onChanged(value.first) : null,
      ),
    );
  }
}

class _PlainBeneficiaryDropdown extends StatelessWidget {
  const _PlainBeneficiaryDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemAsString,
    required this.compareFn,
  });

  final List<dynamic> items;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String Function(dynamic) itemAsString;
  final bool Function(dynamic, dynamic) compareFn;

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<dynamic>(
      selectedItem: value,
      items: (filter, infiniteScrollProps) => items,
      itemAsString: itemAsString,
      compareFn: compareFn,
      validator: (v) => v == null ? 'beneficiaryName'.tr : null,
      popupProps: const PopupProps.menu(showSearchBox: true),
      decoratorProps: DropDownDecoratorProps(
        decoration: _plainInputDecoration('beneficiaryName'.tr).copyWith(
          hintText: 'customerNameExample'.tr,
        ),
      ),
      onChanged: onChanged,
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
      final dateFmt = DateFormat('yyyy/MM/dd');

      return _InputPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'batchSummary'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _BatchSummaryItem(
                    label: 'numberOfChecks'.tr,
                    value: '${rows.length}',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _BatchSummaryItem(
                    label: 'receivedDate'.tr,
                    value: dateFmt.format(controller.receivedDay.value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _BatchSummaryItem(
                    label: 'firstDueDate'.tr,
                    value: dateFmt.format(firstDue),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _BatchSummaryItem(
                    label: 'lastDueDate'.tr,
                    value: dateFmt.format(lastDue),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _BatchSummaryItem extends StatelessWidget {
  const _BatchSummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.sp,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _IncomingBatchRows extends StatelessWidget {
  const _IncomingBatchRows({required this.controller});

  final ChecksController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.incomingBatchRows;
      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: List.generate(
          rows.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _IncomingBatchRowCard(
              controller: controller,
              row: rows[index],
              index: index,
              initiallyExpanded: index == 0,
            ),
          ),
        ),
      );
    });
  }
}

class _IncomingBatchRowCard extends StatefulWidget {
  const _IncomingBatchRowCard({
    required this.controller,
    required this.row,
    required this.index,
    this.initiallyExpanded = false,
  });

  final ChecksController controller;
  final IncomingCheckDraft row;
  final int index;
  final bool initiallyExpanded;

  @override
  State<_IncomingBatchRowCard> createState() => _IncomingBatchRowCardState();
}

class _IncomingBatchRowCardState extends State<_IncomingBatchRowCard> {
  late final FocusNode _bankFocus;
  late bool _expanded;

  ChecksController get c => widget.controller;
  IncomingCheckDraft get row => widget.row;

  @override
  void initState() {
    super.initState();
    _bankFocus = FocusNode();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _bankFocus.dispose();
    super.dispose();
  }

  String _beneficiaryName() {
    final people = c.selectedCustomersSellers.value
        ? c.allCustomersList
        : c.allSellersList;
    final id = int.tryParse(c.selectedValue.value ?? '');
    if (id == null) return '-';
    return people.firstWhereOrNull((e) => e.id == id)?.name ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    final currencies = c.currency.map((e) => e.tr).toList();
    final dateFmt = DateFormat('yyyy/MM/dd');

    return _InputPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'check'.tr} ${widget.index + 1}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (!_expanded) ...[
                          SizedBox(height: 4.h),
                          Obx(
                            () => Text(
                              [
                                row.total.text.isEmpty ? '-' : row.total.text,
                                row.currency.value,
                                dateFmt.format(row.dueDate.value),
                                row.checkId.text,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _PlainTextField(
                    label: 'checkValue'.tr,
                    hint: 'totalExample'.tr,
                    controller: row.total,
                    keyboardType: TextInputType.number,
                    requiredField: true,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: currencies.contains(row.currency.value)
                          ? row.currency.value
                          : null,
                      isExpanded: true,
                      decoration: _plainInputDecoration('currencyy'.tr),
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
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => _ReadOnlyPlainField(
                      label: 'beneficiaryType'.tr,
                      value: c.selectedCustomersSellers.value
                          ? 'customer'.tr
                          : 'seller'.tr,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 3,
                  child: Obx(
                    () => _ReadOnlyPlainField(
                      label: 'beneficiaryName'.tr,
                      value: _beneficiaryName(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _ReadOnlyPlainField(
                      label: 'receivedDate'.tr,
                      value: dateFmt.format(c.receivedDay.value),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Obx(
                    () => _DateTile(
                      label: 'due_date'.tr,
                      value: row.dueDate.value,
                      onChanged: (picked) => row.dueDate.value = picked,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            BankNameField(
              plainStyle: true,
              controller: row.bankName,
              focusNode: _bankFocus,
            ),
            SizedBox(height: 10.h),
            _PlainTextField(
              label: 'checkNumber'.tr,
              hint: 'checkNumberExample'.tr,
              controller: row.checkId,
              keyboardType: TextInputType.number,
              requiredField: true,
            ),
            SizedBox(height: 10.h),
            _PlainTextField(
              label: 'notes'.tr,
              hint: 'notes'.tr,
              controller: row.notes,
              minLines: 2,
              maxLines: 3,
            ),
            SizedBox(height: 10.h),
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
        ],
      ),
    );
  }
}

class _ReadOnlyPlainField extends StatelessWidget {
  const _ReadOnlyPlainField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _plainInputDecoration(label),
      isEmpty: value.isEmpty,
      child: Text(
        value.isEmpty ? '-' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
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
