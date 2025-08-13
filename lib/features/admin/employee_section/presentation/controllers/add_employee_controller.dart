import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/user_data.dart';
import '../../domain/usecases/add_employee_usecase.dart';
import '../../domain/usecases/add_points_usecase.dart';

class AddEmployeeController extends GetxController {
  AddEmployeeUsecase employeeUsecase;
  AddPointsUsecase addPointsUsecase;

  AddEmployeeController({
    required this.employeeUsecase,
    required this.addPointsUsecase,
  });

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
  // final TextEditingController regularWorkingHoursController =
  //     TextEditingController();

  final formKey = GlobalKey<FormState>();

  final Rx<XFile?> documentsImages = Rx<XFile?>(null);
  final Rx<XFile?> employeeImage = Rx<XFile?>(null);

  final List<Map<String, dynamic>> permissionsList = [
    {'name': 'employeeTasks'.tr, 'id': '21', 'permission': false.obs},
    {'name': 'privateTasks'.tr, 'id': '22', 'permission': false.obs},
    {'name': 'employeeDepartment'.tr, 'id': '23', 'permission': false.obs},
    {'name': 'projectManagement'.tr, 'id': '24', 'permission': false.obs},
    {'name': 'messagesDepartment'.tr, 'id': '25', 'permission': false.obs},
    {'name': 'infoCompletion'.tr, 'id': '26', 'permission': false.obs},
    {'name': 'targetSetting'.tr, 'id': '27', 'permission': false.obs},
    {'name': 'followUpDepartment'.tr, 'id': '28', 'permission': false.obs},
    {'name': 'debts'.tr, 'id': '29', 'permission': false.obs},
    {'name': 'sales'.tr, 'id': '30', 'permission': false.obs},
    {'name': 'generalData'.tr, 'id': '31', 'permission': false.obs},
    {'name': 'partnersDepartment'.tr, 'id': '32', 'permission': false.obs},
    {'name': 'inventory'.tr, 'id': '33', 'permission': false.obs},
    {'name': 'boxes'.tr, 'id': '34', 'permission': false.obs},
    {'name': 'purchasingDepartment'.tr, 'id': '35', 'permission': false.obs},
    {'name': 'financialMatters'.tr, 'id': '36', 'permission': false.obs},
    {'name': 'checksandCommitments'.tr, 'id': '37', 'permission': false.obs},
    {'name': 'maintenance'.tr, 'id': '200', 'permission': false.obs},
  ];

  final RxBool isAllPermissionsSelected = false.obs;

  void setAllPermissionsTrue() {
    for (var permission in permissionsList) {
      isAllPermissionsSelected.value = true;
      if (permission['permission'].value == true) {
        continue;
      } else {
        permission['permission'].value = !permission['permission'].value;
      }
    }
  }

  void setAllPermissionsFalse() {
    for (var permission in permissionsList) {
      permission['permission'].value = false;
      isAllPermissionsSelected.value = false;
    }
  }

  List<String> eemployeesList = [
    'employee1',
    'employee2',
    'employee3',
    'employee4',
    'employee5',
  ];
  final TextEditingController employeeConroller = TextEditingController();

  final TextEditingController pointsConroller = TextEditingController();

  final RxBool isVisible = false.obs;

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  final Rx<TimeOfDay> selectedTime = TimeOfDay.now().obs;

  RxBool isLoading = false.obs;

  // add new employee
  void addNewEmployee(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (passwordController.text == confirmPasswordController.text) {
        isLoading(true);
        final token = await UserData.getUserToken();
        String formattedTime =
            '${selectedTime.value.hour.toString().padLeft(2, '0')}:${selectedTime.value.minute.toString().padLeft(2, '0')}';

        final result = await employeeUsecase.call(
          token: token,
          name: employeeNameController.text,
          email: emailController.text,
          phone: phoneNumberController.text,
          subPhone: subPhoneController.text,
          password: passwordController.text,
          passwordConfirmation: confirmPasswordController.text,
          hourWorkPrice: hourlyRateController.text,
          overtimeWorkPrice: overTimeRateController.text,
          numberOfWorkHours: workHoursOfDayController.text,
          startWorkTime: formattedTime,
          documentImg: documentsImages.value,
          employeeImg: employeeImage.value,
          permissions: permissionsList
              .where((e) => e['permission'].value)
              .map<String>((e) => e['id'])
              .toList(),
        );
        result.fold(
          (failure) {
            String errorMessages = '';
            bool permissionsAdded = false;

            failure.data['errors'].forEach((key, value) {
              // لو المفتاح من نوع permissions
              if (key.startsWith('permissions')) {
                if (permissionsAdded) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsAdded = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: errorMessages,
            );
          },
          (success) {
            Future.delayed(
              Duration(milliseconds: 1500),
              () {
                Get.back();
                Get.back();
              },
            );
            Helpers.showCustomDialogSuccess(
              context: context,
              title: 'success'.tr,
              message: 'employeeAddedSuccessfully'.tr,
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
  void addOrMinusPoints(
      BuildContext context, String employeeId, bool isAdd) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final token = await UserData.getUserToken();
      final result = await addPointsUsecase.call(
        token: token,
        employeeId: employeeId,
        points: pointsConroller.text,
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
            Duration(milliseconds: 1500),
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
    }
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    emailController.dispose();
    subPhoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    hourlyRateController.dispose();
    overTimeRateController.dispose();
    workHoursOfDayController.dispose();
    // regularWorkingHoursController.dispose();
    employeeNameController.dispose();
    employeeConroller.dispose();
    pointsConroller.dispose();
    employeeImage.value = null;
    documentsImages.value = null;
    super.dispose();
  }
}
