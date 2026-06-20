import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../data/models/admin_user_model.dart';
import '../../domain/usecases/admin_users_usecase.dart';
import 'employee_section_controller.dart';

class AddAdminController extends GetxController {
  final ManageAdminUserUsecase manageAdminUserUsecase;
  final EmployeeSectionController sectionController;

  AddAdminController({
    required this.manageAdminUserUsecase,
    required this.sectionController,
  });

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();

  final isLoading = false.obs;

  bool get isEdit => Get.arguments?['isEdit'] == true;
  AdminUserModel? get editingAdmin => Get.arguments?['admin'] as AdminUserModel?;

  @override
  void onInit() {
    super.onInit();
    final admin = editingAdmin;
    if (isEdit && admin != null) {
      nameController.text = admin.name;
      emailController.text = admin.email;
      phoneController.text = admin.phone ?? '';
    }
  }

  Future<void> submit(BuildContext context) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (!isEdit &&
        passwordController.text != passwordConfirmationController.text) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'passwordMismatch'.tr,
      );
      return;
    }

    isLoading(true);

    final result = isEdit
        ? await manageAdminUserUsecase.update(
            adminId: editingAdmin!.id.toString(),
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            password: passwordController.text.isEmpty
                ? null
                : passwordController.text,
            passwordConfirmation:
                passwordConfirmationController.text.isEmpty
                    ? null
                    : passwordConfirmationController.text,
          )
        : await manageAdminUserUsecase.create(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            password: passwordController.text,
            passwordConfirmation: passwordConfirmationController.text,
          );

    isLoading(false);

    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: failure.errMessage,
        );
      },
      (success) async {
        await sectionController.getAdminUsers();
        Get.back();
        Get.snackbar('success'.tr, success, snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.onClose();
  }
}
