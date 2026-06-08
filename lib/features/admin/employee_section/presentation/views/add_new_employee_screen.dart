import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/custom_time_picker.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/attendance_settings_service.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_phone_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/add_employee_controller.dart';

class AddNewEmployeeScreen extends GetView<AddEmployeeController> {
  const AddNewEmployeeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title =
        Get.arguments['AddNewEmployeeScreen'] ?? 'addNewEmployee';
    return Scaffold(
      appBar: CustomAppBar(title: title, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      isRequired: true,
                      label: 'employeeName',
                      hintText: 'employeeNameExample',
                      controller: controller.employeeNameController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      isRequired: true,
                      label: 'email',
                      hintText: 'test@mail.com',
                      controller: controller.emailController,
                      validator: (p0) => Validators.validateEmail(
                        p0,
                        Get.locale!.languageCode,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              CustomPhoneField(
                label: 'phoneNumber',
                hintText: '58458XXXXX',
                controller: controller.phoneNumberController,
              ),
              SizedBox(height: 15.h),
              CustomPhoneField(
                label: 'alternatePhone',
                hintText: '58410XXXXX',
                controller: controller.subPhoneController,
              ),
              SizedBox(height: controller.isEditEmployee ? 0 : 15.h),
              controller.isEditEmployee
                  ? const SizedBox()
                  : Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            isRequired: true,
                            label: 'password',
                            hintText: '**********',
                            controller: controller.passwordController,
                            validator: (p0) => Validators.validatePassword(
                              p0,
                              Get.locale!.languageCode,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            isRequired: true,
                            label: 'confirmPassword',
                            hintText: '**********',
                            controller: controller.confirmPasswordController,
                            validator: (p0) => Validators.validatePassword(
                              p0,
                              Get.locale!.languageCode,
                            ),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'hourlyRate',
                      hintText: 'employeeSalaryExample',
                      controller: controller.hourlyRateController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      label: 'overTimeRate',
                      hintText: 'employeeSalaryExample',
                      controller: controller.overTimeRateController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                label: 'workHoursOfDayExample'.tr.split('(')[0],
                hintText: 'workHoursExample',
                controller: controller.workHoursOfDayController,
              ),
              SizedBox(height: 15.w),
              CustomTimePicker(
                isVisible: controller.isVisible,
                onTap: () =>
                    controller.isVisible.value = !controller.isVisible.value,
                selectedTime: controller.selectedTime,
                label: 'regularWorkingHours',
              ),
              SizedBox(height: 15.h),
              controller.isEditEmployee
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.documentsImageList.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                'documentsImages'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: (ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                        SizedBox(height: 5.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () => controller.deleteImage.value
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.documentsImageList
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
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.r),
                                                  child: CachedNetworkImage(
                                                    cacheManager: CacheManager(
                                                      Config(
                                                        'imagesCache',
                                                        stalePeriod:
                                                            const Duration(
                                                                days: 7),
                                                        maxNrOfCacheObjects:
                                                            100,
                                                      ),
                                                    ),
                                                    imageBuilder: (context,
                                                            imageProvider) =>
                                                        Container(
                                                      height: 200.h,
                                                      width: 200.w,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: imageProvider,
                                                          fit: BoxFit.fill,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .medium,
                                                        ),
                                                      ),
                                                    ),
                                                    imageUrl: file.path,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    fadeOutDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
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
                                                          .deleteImage(true);
                                                      controller
                                                          .documentsImageList
                                                          .removeAt(index);
                                                      controller
                                                          .deleteImage(false);
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
                        SizedBox(height: 15.h),
                      ],
                    )
                  : const SizedBox.shrink(),
              MediaUploadButton(
                title: 'documentsImages',
                onFilesChanged: (val) {
                  controller.documentsImageList.addAll(val);
                },
                allowedType: MediaType.image,
              ),
              SizedBox(height: 15.h),
              controller.isEditEmployee
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.employeeImageList.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                'employeeImage'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: (ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                        SizedBox(height: 5.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () => controller.deleteImage.value
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.employeeImageList
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
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.r),
                                                  child: file.path
                                                          .startsWith('http')
                                                      ? CachedNetworkImage(
                                                          cacheManager:
                                                              CacheManager(
                                                            Config(
                                                              'imagesCache',
                                                              stalePeriod:
                                                                  const Duration(
                                                                      days: 7),
                                                              maxNrOfCacheObjects:
                                                                  100,
                                                            ),
                                                          ),
                                                          imageBuilder: (context,
                                                                  imageProvider) =>
                                                              Container(
                                                            height: 200.h,
                                                            width: 200.w,
                                                            decoration:
                                                                BoxDecoration(
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    imageProvider,
                                                                fit:
                                                                    BoxFit.fill,
                                                                filterQuality:
                                                                    FilterQuality
                                                                        .medium,
                                                              ),
                                                            ),
                                                          ),
                                                          imageUrl: file.path,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const Center(
                                                                  child:
                                                                      CircularProgressIndicator()),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        )
                                                      : Image.file(
                                                          file,
                                                          height: 200.h,
                                                          width: 200.w,
                                                          fit: BoxFit.fill,
                                                        ),
                                                ),
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      controller
                                                          .deleteImage(true);
                                                      controller
                                                          .employeeImageList
                                                          .removeAt(index);
                                                      controller
                                                          .deleteImage(false);
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
                        SizedBox(height: 15.h),
                      ],
                    )
                  : const SizedBox.shrink(),
              MediaUploadButton(
                title: 'employeeImage',
                onFilesChanged: (val) {
                  controller.employeeImageList.addAll(val);
                },
                allowedType: MediaType.image,
              ),
              SizedBox(height: 10.h),
              // Weekly days off (new)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'weeklyDaysOffTitle'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _WeeklyDayChip(controller: controller, keyName: 'saturday'),
                  _WeeklyDayChip(controller: controller, keyName: 'sunday'),
                  _WeeklyDayChip(controller: controller, keyName: 'monday'),
                  _WeeklyDayChip(controller: controller, keyName: 'tuesday'),
                  _WeeklyDayChip(controller: controller, keyName: 'wednesday'),
                  _WeeklyDayChip(controller: controller, keyName: 'thursday'),
                  _WeeklyDayChip(controller: controller, keyName: 'friday'),
                ],
              ),
              SizedBox(height: 15.h),
              // Fingerprint settings (new)
              _FingerprintSettingsCard(controller: controller),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Text(
                    'permissions'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => controller.isAllPermissionsSelected.value
                        ? controller.setAllPermissionsFalse()
                        : controller.setAllPermissionsTrue(),
                    child: Obx(
                      () => Text(
                        controller.isAllPermissionsSelected.value
                            ? 'unselectAll'.tr
                            : 'selectAll'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.solid,
                            ),
                      ),
                    ),
                  )
                ],
              ),
              ...List.generate(
                controller.permissionsList.length,
                (index) => CustomCheckBox(
                  title: controller.permissionsList[index]['name'],
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor2,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                  value: controller.permissionsList[index]['permission'],
                  onChanged: (value) {
                    controller.permissionsList[index]['permission'].value =
                        value;
                  },
                ),
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text:
                    title == 'editEmployee' ? 'saveChanges' : 'addNewEmployee',
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                height: 50.h,
                onPressed: () {
                  controller.isLoading.value
                      ? null
                      : controller.addNewEmployee(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyDayChip extends StatelessWidget {
  const _WeeklyDayChip({
    required this.controller,
    required this.keyName,
  });

  final AddEmployeeController controller;
  final String keyName; // "monday".."sunday"

  @override
  Widget build(BuildContext context) {
    final labelKey = 'day_$keyName';
    return Obx(() {
      final selected = controller.weeklyDaysOff[keyName]!.value;
      return FilterChip(
        label: Text(labelKey.tr),
        selected: selected,
        onSelected: (v) => controller.weeklyDaysOff[keyName]!.value = v,
      );
    });
  }
}

class _FingerprintSettingsCard extends StatelessWidget {
  const _FingerprintSettingsCard({required this.controller});

  final AddEmployeeController controller;

  Future<void> _unlinkIfPossible(String deviceUserId) async {
    await AttendanceSettingsService.instance.ensureLoaded();
    final deviceId = AttendanceSettingsService.instance.defaultDeviceId.value;
    final api =
        Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;
    if (api == null || deviceId == null || deviceId <= 0) return;
    try {
      await api.post(
        'admin/fingerprint/users/$deviceUserId/unlink',
        data: {'device_id': deviceId},
      );
    } catch (_) {}
  }

  Future<void> _setFingerprintEnabled(bool v) async {
    if (v) {
      controller.fingerprintEnabled.value = true;
      return;
    }
    final old = controller.deviceUserIdController.text.trim();
    controller.fingerprintEnabled.value = false;
    controller.deviceUserIdController.text = '';
    if (controller.isEditEmployee && old.isNotEmpty) {
      await _unlinkIfPossible(old);
    }
  }

  Future<void> _pickDeviceUser(BuildContext context) async {
    await AttendanceSettingsService.instance.ensureLoaded();
    final deviceId = AttendanceSettingsService.instance.defaultDeviceId.value;
    final api =
        Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;
    if (deviceId == null || deviceId <= 0) {
      Get.snackbar(
        'info'.tr,
        'fingerprintDefaultDeviceRequired'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (api == null) {
      Get.snackbar(
        'error'.tr,
        'تعذر الاتصال بالسيرفر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final res = await api.get(
        'admin/fingerprint/users',
        queryParameters: {'device_id': deviceId},
      );
      final data = res.data;
      if (data is! Map || data['status']?.toString() != 'success') {
        Get.snackbar(
          'error'.tr,
          (data is Map ? data['message']?.toString() : null) ??
              'فشل تحميل مستخدمي الجهاز',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final list = data['users'];
      final users = (list is List)
          ? list.map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (!context.mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DeviceUserPickerSheet(
          users: users,
          currentEmployeeId: controller.isEditEmployee
              ? controller.employeeService.employeeDetails.value?.id
              : null,
        ),
      );
      if (selected == null) return;
      final id = selected['device_user_id']?.toString().trim() ?? '';
      if (id.isEmpty) return;
      controller.deviceUserIdController.text = id;
      controller.fingerprintEnabled.value = true;

      // If editing an existing employee, also link in backend so device user list is accurate.
      if (controller.isEditEmployee) {
        final employeeId = controller.employeeService.employeeDetails.value!.id;
        try {
          await api.post(
            'admin/fingerprint/users/$id/link',
            data: {'employee_id': employeeId, 'device_id': deviceId},
          );
        } catch (_) {}
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'fingerprintAttendance'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
          ),
          SizedBox(height: 8.h),
          Obx(() {
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: controller.fingerprintEnabled.value,
              onChanged: (v) => _setFingerprintEnabled(v),
              title: Text(
                'enable'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              subtitle: Text(
                'deviceUserId'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            );
          }),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.deviceUserIdController,
                  decoration: InputDecoration(
                    hintText: 'deviceUserId'.tr,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
                onPressed: () => _pickDeviceUser(context),
                child: Text('select'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceUserPickerSheet extends StatefulWidget {
  const _DeviceUserPickerSheet({
    required this.users,
    this.currentEmployeeId,
  });

  final List<Map<String, dynamic>> users;
  final int? currentEmployeeId;

  @override
  State<_DeviceUserPickerSheet> createState() => _DeviceUserPickerSheetState();
}

class _DeviceUserPickerSheetState extends State<_DeviceUserPickerSheet> {
  final TextEditingController _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.users;
    return widget.users.where((u) {
      final id = u['device_user_id']?.toString().toLowerCase() ?? '';
      final name = u['name']?.toString().toLowerCase() ?? '';
      final emp = u['linked_employee_name']?.toString().toLowerCase() ?? '';
      return id.contains(q) || name.contains(q) || emp.contains(q);
    }).toList();
  }

  String _linkLabel(Map<String, dynamic> u) {
    final linked = u['status']?.toString().toLowerCase() == 'linked';
    if (!linked) return 'fingerprintUnlinked'.tr;

    final linkedEmpId =
        int.tryParse(u['linked_employee_id']?.toString() ?? '');
    final empName = u['linked_employee_name']?.toString().trim() ?? '';
    final currentId = widget.currentEmployeeId;

    if (currentId != null &&
        linkedEmpId != null &&
        linkedEmpId == currentId) {
      return 'fingerprintLinkedToCurrentEmployee'.tr;
    }
    if (empName.isNotEmpty) {
      return '${'fingerprintLinkedWith'.tr}: $empName';
    }
    return 'fingerprintLinked'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 14.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'fingerprintDeviceUsers'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          TextField(
            controller: _q,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'search'.tr,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 420.h,
            child: rows.isEmpty
                ? Center(child: Text('noData'.tr))
                : ListView.separated(
                    itemBuilder: (_, i) {
                      final u = rows[i];
                      final id = u['device_user_id']?.toString() ?? '';
                      final name = u['name']?.toString().trim() ?? '';
                      final linked =
                          u['status']?.toString().toLowerCase() == 'linked';
                      final linkLabel = _linkLabel(u);
                      final linkedEmpId =
                          int.tryParse(u['linked_employee_id']?.toString() ?? '');
                      final isCurrentEmployee = widget.currentEmployeeId != null &&
                          linkedEmpId != null &&
                          linkedEmpId == widget.currentEmployeeId;

                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: linked
                                ? (isCurrentEmployee
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFF59E0B))
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        title: Text(
                          name.isNotEmpty ? 'PIN $id • $name' : 'PIN $id',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              Icon(
                                linked
                                    ? Icons.link_rounded
                                    : Icons.link_off_rounded,
                                size: 14.sp,
                                color: linked
                                    ? (isCurrentEmployee
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFD97706))
                                    : const Color(0xFF9CA3AF),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  linkLabel,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: linked
                                        ? (isCurrentEmployee
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFB45309))
                                        : const Color(0xFF6B7280),
                                    fontWeight: linked
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: (linked
                                    ? (isCurrentEmployee
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFF59E0B))
                                    : const Color(0xFF9CA3AF))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            linked ? 'fingerprintLinked'.tr : 'fingerprintUnlinked'.tr,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: linked
                                  ? (isCurrentEmployee
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706))
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemCount: rows.length,
                  ),
          ),
        ],
      ),
    );
  }
}
