import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/custom_time_picker.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
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
    final isEdit = title == 'editEmployee';

    return Scaffold(
      appBar: CustomAppBar(title: title, action: false),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 16.h),
          children: [
            _EmployeeFormSection(
              icon: Icons.badge_outlined,
              title: 'بيانات الموظف',
              children: [
                _AdaptiveFields(
                  children: [
                    _AdaptiveField(
                      width: .50,
                      child: CustomTextField(
                        isRequired: true,
                        label: 'employeeName',
                        hintText: 'employeeNameExample',
                        controller: controller.employeeNameController,
                      ),
                    ),
                    _AdaptiveField(
                      width: .50,
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
                    _AdaptiveField(
                      width: .50,
                      child: CustomPhoneField(
                        label: 'phoneNumber',
                        hintText: '58458XXXXX',
                        controller: controller.phoneNumberController,
                      ),
                    ),
                    _AdaptiveField(
                      width: .50,
                      child: CustomPhoneField(
                        label: 'alternatePhone',
                        hintText: '58410XXXXX',
                        controller: controller.subPhoneController,
                      ),
                    ),
                    if (!controller.isEditEmployee) ...[
                      _AdaptiveField(
                        width: .50,
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
                      _AdaptiveField(
                        width: .50,
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
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _EmployeeFormSection(
              icon: Icons.schedule_outlined,
              title: 'الدوام والأجور',
              collapsible: true,
              initiallyExpanded: false,
              children: [
                _CompactWorkFields(controller: controller),
                SizedBox(height: 14.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'weeklyDaysOffTitle'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
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
                    _WeeklyDayChip(
                        controller: controller, keyName: 'wednesday'),
                    _WeeklyDayChip(controller: controller, keyName: 'thursday'),
                    _WeeklyDayChip(controller: controller, keyName: 'friday'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _EmployeeFormSection(
              icon: Icons.photo_library_outlined,
              title: 'الصور والمستندات',
              collapsible: true,
              initiallyExpanded: false,
              children: [
                MediaUploadButton(
                  title: 'documentsImages',
                  initialFiles: controller.documentsImageList,
                  onFilesChanged: (files) {
                    controller.documentsImageList
                      ..clear()
                      ..addAll(files);
                  },
                  allowedType: MediaType.image,
                ),
                SizedBox(height: 8.h),
                MediaUploadButton(
                  title: 'employeeImage',
                  initialFiles: controller.employeeImageList,
                  onFilesChanged: (files) {
                    controller.employeeImageList
                      ..clear()
                      ..addAll(files);
                  },
                  allowedType: MediaType.image,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _EmployeeFormSection(
              icon: Icons.fingerprint_outlined,
              title: 'البصمة',
              collapsible: true,
              initiallyExpanded: false,
              children: [
                _FingerprintSettingsCard(controller: controller),
              ],
            ),
            SizedBox(height: 8.h),
            _EmployeeFormSection(
              icon: Icons.admin_panel_settings_outlined,
              title: 'permissions'.tr,
              collapsible: true,
              initiallyExpanded: false,
              trailing: Obx(
                () => controller.canEditPermissionAssignments.value
                    ? TextButton(
                        onPressed: () =>
                            controller.isAllPermissionsSelected.value
                                ? controller.setAllPermissionsFalse()
                                : controller.setAllPermissionsTrue(),
                        child: Text(
                          controller.isAllPermissionsSelected.value
                              ? 'unselectAll'.tr
                              : 'selectAll'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor6
                                        : AppColors.customGreyColor,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              children: [
                Obx(
                  () {
                    if (!controller.canEditPermissionAssignments.value) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.customOrange3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color:
                                AppColors.customOrange3.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'cannotEditOwnPermissions'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.customOrange3,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      );
                    }

                    return _PermissionGroups(controller: controller);
                  },
                ),
              ],
            ),
            SizedBox(height: 10.h),
            AppButton(
              isLoading: controller.isLoading,
              text: isEdit ? 'saveChanges' : 'addNewEmployee',
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
              height: 48.h,
              onPressed: () {
                controller.isLoading.value
                    ? null
                    : controller.addNewEmployee(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionGroups extends StatelessWidget {
  const _PermissionGroups({required this.controller});

  final AddEmployeeController controller;

  @override
  Widget build(BuildContext context) {
    final groups = controller.groupedVisiblePermissions;
    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          _PermissionGroupCard(group: groups[i]),
          if (i != groups.length - 1) SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({required this.group});

  final Map<String, dynamic> group;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final permissions =
        List<Map<String, dynamic>>.from(group['permissions'] as List);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                group['icon'] as IconData,
                size: 16.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  group['title'].toString(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 680
                  ? (constraints.maxWidth - 10.w) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10.w,
                runSpacing: 2.h,
                children: [
                  for (final permission in permissions)
                    SizedBox(
                      width: itemWidth,
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomCheckBox(
                              title: permission['name'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: isDark
                                        ? AppColors.customGreyColor6
                                        : AppColors.customGreyColor2,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                              value: permission['permission'],
                              onChanged: (value) {
                                permission['permission'].value = value;
                              },
                            ),
                          ),
                          if (permission['adminOnly'] == true) ...[
                            SizedBox(width: 4.w),
                            Tooltip(
                              message: 'adminOnlyPermission'.tr,
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 14.sp,
                                color: AppColors.customOrange3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmployeeFormSection extends StatefulWidget {
  const _EmployeeFormSection({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<_EmployeeFormSection> createState() => _EmployeeFormSectionState();
}

class _EmployeeFormSectionState extends State<_EmployeeFormSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final showBody = !widget.collapsible || _expanded;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.collapsible
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.primaryColor,
                    size: 17.sp,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                  ),
                ),
                if (widget.trailing != null && showBody) widget.trailing!,
                if (widget.collapsible)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
          ),
          if (showBody) ...[
            SizedBox(height: 9.h),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}

class _CompactWorkFields extends StatelessWidget {
  const _CompactWorkFields({required this.controller});

  final AddEmployeeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TinyNumberField(
                label: 'hourlyRate',
                hintText: 'employeeSalaryExample',
                controller: controller.hourlyRateController,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: _TinyNumberField(
                label: 'workHoursOfDayExample'.tr.split('(')[0],
                hintText: 'workHoursExample',
                controller: controller.workHoursOfDayController,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: _TinyNumberField(
                label: 'overTimeRate',
                hintText: 'employeeSalaryExample',
                controller: controller.overTimeRateController,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        CustomTimePicker(
          isVisible: controller.isVisible,
          onTap: () => controller.isVisible.value = !controller.isVisible.value,
          selectedTime: controller.selectedTime,
          label: 'regularWorkingHours',
        ),
      ],
    );
  }
}

class _TinyNumberField extends StatelessWidget {
  const _TinyNumberField({
    required this.label,
    required this.hintText,
    required this.controller,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final fill = isDark ? AppColors.customGreyColor : AppColors.whiteColor2;
    final labelColor =
        isDark ? AppColors.customGreyColor6 : AppColors.customGreyColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: labelColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 5.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
          decoration: InputDecoration(
            hintText: hintText.tr,
            hintStyle: TextStyle(fontSize: 11.sp),
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdaptiveField {
  const _AdaptiveField({required this.child, this.width = .5});

  final Widget child;
  final double width;
}

class _AdaptiveFields extends StatelessWidget {
  const _AdaptiveFields({required this.children});

  final List<_AdaptiveField> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final gap = 10.w;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i].child,
                if (i != children.length - 1) SizedBox(height: 8.h),
              ],
            ],
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: 12.h,
          children: children.map((field) {
            final width = (constraints.maxWidth * field.width) - gap;
            return SizedBox(
              width: width.clamp(180.0, constraints.maxWidth),
              child: field.child,
            );
          }).toList(),
        );
      },
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
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
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
                    fillColor:
                        isDark ? Colors.white10 : const Color(0xFFF9FAFB),
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

    final linkedEmpId = int.tryParse(u['linked_employee_id']?.toString() ?? '');
    final empName = u['linked_employee_name']?.toString().trim() ?? '';
    final currentId = widget.currentEmployeeId;

    if (currentId != null && linkedEmpId != null && linkedEmpId == currentId) {
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
          SizedBox(height: 8.h),
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
                      final linkedEmpId = int.tryParse(
                          u['linked_employee_id']?.toString() ?? '');
                      final isCurrentEmployee =
                          widget.currentEmployeeId != null &&
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
                            linked
                                ? 'fingerprintLinked'.tr
                                : 'fingerprintUnlinked'.tr,
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
