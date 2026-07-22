import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/user_data.dart';
import '../../domain/usecases/add_employee_usecase.dart';
import '../../domain/usecases/add_points_usecase.dart';
import '../../domain/usecases/get_permissions_usecase.dart';
import 'employee_section_controller.dart';
import 'employee_service.dart';

class _PermissionGroupMeta {
  const _PermissionGroupMeta({
    required this.key,
    required this.title,
    required this.icon,
  });

  final String key;
  final String title;
  final IconData icon;
}

class AddEmployeeController extends GetxController {
  AddEmployeeUsecase employeeUsecase;
  AddPointsUsecase addPointsUsecase;
  GetPermissionsUsecase getPermissionsUsecase;
  EmployeeService employeeService;

  AddEmployeeController({
    required this.employeeUsecase,
    required this.addPointsUsecase,
    required this.getPermissionsUsecase,
    required this.employeeService,
  });
  final bool isEditEmployee =
      Get.arguments['AddNewEmployeeScreen'] == 'editEmployee' ? true : false;

  @override
  void onInit() {
    super.onInit();
    if (isEditEmployee) {
      employeeNameController.text = employeeService.employeeDetails.value!.name;
      emailController.text = employeeService.employeeDetails.value!.email;
      phoneNumberController.text = PhoneFormatHelper.forApi(
        employeeService.employeeDetails.value!.phone,
      );
      subPhoneController.text = PhoneFormatHelper.forApi(
        employeeService.employeeDetails.value!.subPhone,
      );
      hourlyRateController.text =
          employeeService.employeeDetails.value!.hourWorkPrice;
      overTimeRateController.text =
          employeeService.employeeDetails.value!.overtimeWorkPrice;
      workHoursOfDayController.text =
          employeeService.employeeDetails.value!.numberOfWorkHours;

      for (var docImgPath
          in employeeService.employeeDetails.value!.documentImg) {
        documentsImageList.add(File(docImgPath));
      }
      for (var docImgPath
          in employeeService.employeeDetails.value!.employeeImg) {
        employeeImageList.add(File(docImgPath));
      }
      selectedTime.value = parseTimeOfDay(
        employeeService.employeeDetails.value!.startWorkTime,
      );
      _applyEditedEmployeePermissionSelection();

      // Weekly days off (new)
      final existing = employeeService.employeeDetails.value!.weeklyDaysOff;
      for (final d in existing) {
        final key = d.toLowerCase();
        if (weeklyDaysOff.containsKey(key)) {
          weeklyDaysOff[key]!.value = true;
        }
      }

      // Fingerprint
      fingerprintEnabled.value =
          employeeService.employeeDetails.value!.fingerprintEnabled;
      deviceUserIdController.text =
          employeeService.employeeDetails.value!.deviceUserId ?? '';
      if (userType == 'employee') {
        canEditPermissionAssignments.value = false;
      }
      _loadPermissionEditContext();
    } else {
      // Default weekly day off: Friday (week starts Saturday)
      weeklyDaysOff['friday']!.value = true;
    }
    _loadPermissionsFromServer();
  }

  final formKey = GlobalKey<FormState>();

  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController subPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController overTimeRateController = TextEditingController();
  final TextEditingController workHoursOfDayController =
      TextEditingController();

  // Fingerprint settings
  final RxBool fingerprintEnabled = false.obs;
  final TextEditingController deviceUserIdController = TextEditingController();

  final List<File> documentsImageList = [];
  final List<File> employeeImageList = [];

  static const Set<String> employeeHiddenPermissionIds = {
    '1', // Debts
    '6', // Special Tasks
    '11', // Boxes Section
    '14', // Checks
  };

  final RxList<Map<String, dynamic>> permissionsList = <Map<String, dynamic>>[
    {
      'name': 'debts'.tr,
      'id': '1',
      'group': 'financial',
      'permission': false.obs
    },
    {
      'name': 'followUpDepartment'.tr,
      'id': '2',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'targetSetting'.tr,
      'id': '3',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'projectManagement'.tr,
      'id': '4',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'employeeDepartment'.tr,
      'id': '5',
      'group': 'employees',
      'permission': false.obs
    },
    {
      'name': 'privateTasks'.tr,
      'id': '6',
      'group': 'employees',
      'permission': false.obs
    },
    {
      'name': 'employeeTasks'.tr,
      'id': '7',
      'group': 'employees',
      'permission': false.obs
    },
    {'name': 'sales'.tr, 'id': '8', 'group': 'sales', 'permission': false.obs},
    {
      'name': 'generalData'.tr,
      'id': '9',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'partnershipSectionPermission'.tr,
      'id': '10',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'boxes'.tr,
      'id': '11',
      'group': 'financial',
      'permission': false.obs
    },
    {
      'name': 'purchasingDepartment'.tr,
      'id': '12',
      'group': 'stock',
      'permission': false.obs
    },
    {
      'name': 'financialMatters'.tr,
      'id': '13',
      'group': 'financial',
      'permission': false.obs
    },
    {
      'name': 'checksandCommitments'.tr,
      'id': '14',
      'group': 'financial',
      'permission': false.obs
    },
    {
      'name': 'maintenance'.tr,
      'id': '15',
      'group': 'maintenance',
      'permission': false.obs
    },
    {'name': 'stock'.tr, 'id': '16', 'group': 'stock', 'permission': false.obs},
    {
      'name': 'whatsappSectionPermission'.tr,
      'id': '17',
      'group': 'communication',
      'permission': false.obs
    },
    {
      'name': 'completeData'.tr,
      'id': '40',
      'group': 'general',
      'permission': false.obs
    },
    {
      'name': 'salesDailyCloseReviewPermission'.tr,
      'id': '41',
      'group': 'sales',
      'permission': false.obs
    },
    {
      'name': 'salesCancelClosedReviewPermission'.tr,
      'id': '42',
      'group': 'sales',
      'permission': false.obs
    },
    {
      'name': 'impersonateEmployeePermission'.tr,
      'id': '43',
      'group': 'employees',
      'permission': false.obs
    },
    {
      'name': 'costPricePermission'.tr,
      'id': '44',
      'group': 'stock',
      'permission': false.obs
    },
    {
      'name': 'technicalSupport'.tr,
      'id': '49',
      'group': 'communication',
      'permission': false.obs
    },
    {
      'name': 'editEmployeeTaskPermission'.tr,
      'id': '45',
      'group': 'employees',
      'permission': false.obs
    },
    {
      'name': 'cloneEmployeeTaskPermission'.tr,
      'id': '46',
      'group': 'employees',
      'permission': false.obs
    },
    {
      'name': 'stockInventorySettingsPermission'.tr,
      'id': '47',
      'group': 'stock',
      'permission': false.obs
    },
    {
      'name': 'dailyBoxes'.tr,
      'id': '48',
      'group': 'financial',
      'permission': false.obs
    },
  ].obs;

  final RxBool isAllPermissionsSelected = false.obs;
  final RxBool canEditPermissionAssignments = true.obs;

  List<Map<String, dynamic>> get visiblePermissionsList {
    if (userType != 'employee') {
      return permissionsList;
    }

    return permissionsList
        .where((permission) =>
            !employeeHiddenPermissionIds.contains(permission['id'].toString()))
        .toList();
  }

  void _applyEditedEmployeePermissionSelection() {
    if (!isEditEmployee || employeeService.employeeDetails.value == null) {
      return;
    }

    final selectedIds = employeeService.employeeDetails.value!.permissions
        .map((permission) => permission.permissionId)
        .toSet();
    for (final element in permissionsList) {
      element['permission'].value =
          selectedIds.contains(int.tryParse(element['id'].toString()) ?? -1);
    }
  }

  Future<void> _loadPermissionsFromServer() async {
    try {
      final rows = await getPermissionsUsecase.call();
      if (rows.isEmpty) return;

      permissionsList.assignAll(rows.map(_permissionFromApi));
      _applyEditedEmployeePermissionSelection();
    } catch (_) {
      _applyEditedEmployeePermissionSelection();
    }
  }

  Map<String, dynamic> _permissionFromApi(Map<String, dynamic> row) {
    final id = row['id'] ?? row['permission_id'];
    final nameAr = row['name'] ?? row['permission_name'];
    final nameEn = row['name_en'] ?? row['permission_name_en'];
    final group = row['group_key'] ?? _permissionGroupForName(nameEn);
    final adminOnly = row['admin_only'] == true ||
        employeeHiddenPermissionIds.contains(id.toString());
    final preferredName = Get.locale?.languageCode == 'en' ? nameEn : nameAr;
    final fallbackName = nameAr ?? nameEn ?? '';
    final displayName = preferredName?.toString().trim().isNotEmpty == true
        ? preferredName.toString()
        : fallbackName.toString();

    return {
      'name': displayName,
      'id': id.toString(),
      'group': group.toString(),
      'permission': false.obs,
      'adminOnly': adminOnly,
    };
  }

  String _permissionGroupForName(dynamic nameEn) {
    const groupsByName = {
      'Sales': 'sales',
      'Sales Daily Close Review': 'sales',
      'Sales Cancel Closed Review': 'sales',
      'Stock': 'stock',
      'Purchasing Section': 'stock',
      'Cost Price': 'stock',
      'Stock Inventory Settings': 'stock',
      'Employees Section': 'employees',
      'Employee Tasks': 'employees',
      'Special Tasks': 'employees',
      'Employee Impersonation': 'employees',
      'Edit Employee Task': 'employees',
      'Clone Employee Task': 'employees',
      'Debts': 'financial',
      'Boxes Section': 'financial',
      'Expenses and Financial Affairs': 'financial',
      'Checks': 'financial',
      'Daily Boxes': 'financial',
      'Maintenance': 'maintenance',
      'Messages Section': 'communication',
      'Technical Support': 'communication',
    };
    return groupsByName[nameEn?.toString()] ?? 'general';
  }

  List<Map<String, dynamic>> get groupedVisiblePermissions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final permission in visiblePermissionsList) {
      final group = permission['group']?.toString() ?? 'general';
      final row = Map<String, dynamic>.from(permission)
        ..['adminOnly'] = permission['adminOnly'] == true ||
            employeeHiddenPermissionIds.contains(permission['id'].toString());
      grouped.putIfAbsent(group, () => <Map<String, dynamic>>[]).add(row);
    }

    return _permissionGroupOrder
        .where((group) => grouped[group.key]?.isNotEmpty == true)
        .map(
          (group) => {
            'key': group.key,
            'title': group.title,
            'icon': group.icon,
            'permissions': grouped[group.key]!,
          },
        )
        .toList();
  }

  static const List<_PermissionGroupMeta> _permissionGroupOrder = [
    _PermissionGroupMeta(
      key: 'sales',
      title: 'المبيعات',
      icon: Icons.point_of_sale_outlined,
    ),
    _PermissionGroupMeta(
      key: 'stock',
      title: 'المخزون والمشتريات',
      icon: Icons.inventory_2_outlined,
    ),
    _PermissionGroupMeta(
      key: 'employees',
      title: 'الموظفين والمهام',
      icon: Icons.groups_2_outlined,
    ),
    _PermissionGroupMeta(
      key: 'financial',
      title: 'المالية والصناديق',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PermissionGroupMeta(
      key: 'maintenance',
      title: 'الصيانة',
      icon: Icons.build_circle_outlined,
    ),
    _PermissionGroupMeta(
      key: 'communication',
      title: 'التواصل والدعم',
      icon: Icons.support_agent_outlined,
    ),
    _PermissionGroupMeta(
      key: 'general',
      title: 'إعدادات عامة',
      icon: Icons.tune_outlined,
    ),
  ];

  Future<void> _loadPermissionEditContext() async {
    if (userType != 'employee') {
      canEditPermissionAssignments.value = true;
      return;
    }

    final savedUser = await UserData.getSavedUser();
    final currentEmployeeId = savedUser?.user.employee.id;
    final editedEmployeeId = employeeService.employeeDetails.value?.id;
    canEditPermissionAssignments.value =
        currentEmployeeId == null || currentEmployeeId != editedEmployeeId;
  }

  void setAllPermissionsTrue() {
    if (!canEditPermissionAssignments.value) return;
    for (var permission in visiblePermissionsList) {
      isAllPermissionsSelected.value = true;
      if (permission['permission'].value == true) {
        continue;
      } else {
        permission['permission'].value = !permission['permission'].value;
      }
    }
  }

  void setAllPermissionsFalse() {
    if (!canEditPermissionAssignments.value) return;
    for (var permission in visiblePermissionsList) {
      permission['permission'].value = false;
      isAllPermissionsSelected.value = false;
    }
  }

  final TextEditingController employeeConroller = TextEditingController();

  final TextEditingController pointsConroller = TextEditingController();
  final TextEditingController notesConroller = TextEditingController();

  final RxBool isVisible = false.obs;

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  final Rx<TimeOfDay> selectedTime = TimeOfDay.now().obs;

  // Weekly days off selection
  final Map<String, RxBool> weeklyDaysOff = {
    'saturday': false.obs,
    'sunday': false.obs,
    'monday': false.obs,
    'tuesday': false.obs,
    'wednesday': false.obs,
    'thursday': false.obs,
    'friday': false.obs,
  };

  List<String> get selectedWeeklyDaysOff => weeklyDaysOff.entries
      .where((e) => e.value.value)
      .map((e) => e.key)
      .toList();

  RxBool isLoading = false.obs;

  // add new employee
  void addNewEmployee(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (passwordController.text == confirmPasswordController.text) {
        isLoading(true);
        String formattedTime =
            '${selectedTime.value.hour.toString().padLeft(2, '0')}:${selectedTime.value.minute.toString().padLeft(2, '0')}';
        final result = await employeeUsecase.call(
          employeeId: isEditEmployee
              ? employeeService.employeeDetails.value!.id.toString()
              : null,
          name: employeeNameController.text,
          email: emailController.text,
          phone: PhoneFormatHelper.forApi(phoneNumberController.text),
          subPhone: PhoneFormatHelper.forApi(subPhoneController.text),
          password: passwordController.text,
          passwordConfirmation: confirmPasswordController.text,
          hourWorkPrice: hourlyRateController.text,
          overtimeWorkPrice: overTimeRateController.text,
          numberOfWorkHours: workHoursOfDayController.text,
          startWorkTime: formattedTime,
          documentImg: documentsImageList,
          employeeImg: employeeImageList,
          permissions: permissionsList
              .where((e) => e['permission'].value)
              .map<String>((e) => e['id'])
              .toList(),
          weeklyDaysOff: selectedWeeklyDaysOff,
          fingerprintEnabled: fingerprintEnabled.value,
          deviceUserId: deviceUserIdController.text.trim().isEmpty
              ? null
              : deviceUserIdController.text.trim(),
        );
        result.fold(
          (failure) {
            String errorMessages = '';
            bool permissionsAdded = false;

            final errors = failure.data?['errors'] as Map<String, dynamic>?;

            if (errors != null) {
              errors.forEach((key, value) {
                // لو المفتاح من نوع permissions
                if (key.startsWith('permissions')) {
                  if (!permissionsAdded) {
                    errorMessages += "Permissions: ${value.first}\n";
                    permissionsAdded = true;
                  }
                } else {
                  for (var msg in value) {
                    errorMessages += "- $key: $msg\n";
                  }
                }
              });
            } else {
              // fallback message لو مفيش errors
              errorMessages = failure.data?['message'] ?? failure.errMessage;
            }

            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: errorMessages,
            );
          },
          (success) {
            if (isEditEmployee) {
              Get.find<EmployeeSectionController>().getEmployeeDetails(
                employeeService.employeeDetails.value!.id.toString(),
              );
              Get.find<EmployeeSectionController>().getOvertimeAndLoan();
              Get.find<EmployeeSectionController>().getFinancialDues();
              Get.find<EmployeeSectionController>().getWorkingTimes();
            }
            Get.find<EmployeeSectionController>().getEmployee();

            Future.delayed(
              const Duration(milliseconds: 1000),
              () {
                Get.back();
                Get.back();
              },
            );
            Helpers.showCustomDialogSuccess(
              context: context,
              title: 'success'.tr,
              message: success,
            );
          },
        );
        isLoading(false);
      } else {
        Helpers.showCustomDialogSecondaryError(
          context: Get.context!,
          title: 'error'.tr,
          message: 'PasswordsNotMatch'.tr,
        );
      }
    }
  }

  // add or minus points
  void addOrMinusPoints(BuildContext context, bool isAdd) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addPointsUsecase.call(
        employeeId: employeeConroller.text,
        points: pointsConroller.text,
        notes: notesConroller.text,
        isAdd: isAdd,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          Future.delayed(
            const Duration(milliseconds: 100),
            () {
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      Get.find<EmployeeSectionController>().getEmployee();
      isLoading(false);
    }
  }

  RxBool deleteImage = false.obs;

  @override
  void onClose() {
    phoneNumberController.dispose();
    emailController.dispose();
    subPhoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    hourlyRateController.dispose();
    overTimeRateController.dispose();
    workHoursOfDayController.dispose();
    deviceUserIdController.dispose();
    // regularWorkingHoursController.dispose();
    employeeNameController.dispose();
    employeeConroller.dispose();
    pointsConroller.dispose();
    notesConroller.dispose();
    super.onClose();
  }
}
