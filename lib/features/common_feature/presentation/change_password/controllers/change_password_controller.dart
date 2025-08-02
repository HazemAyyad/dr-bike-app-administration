import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/user_data.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../auth/domain/usecases/change_password_usecase.dart';

class ChangePasswordController extends GetxController {
  ChangePassword changePassword;

  ChangePasswordController({required this.changePassword});

  final formKey = GlobalKey<FormState>();
  // متغيرات لكلمة المرور
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  RxBool oldPasswordVisibility = true.obs;
  RxBool newPasswordVisibility = true.obs;
  RxBool confirmNewPasswordVisibility = true.obs;

  RxBool isLoading = false.obs;

  // دالة لحفظ تغييرات كلمة المرور
  void savePasswordChanges(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (newPasswordController.text == confirmPasswordController.text) {
        isLoading(true);

        String userToken = await UserData.getUserToken();

        final result = await changePassword.call(
          token: userToken,
          oldPassword: oldPasswordController.text,
          password: newPasswordController.text,
          confirmPassword: confirmPasswordController.text,
        );
        result.fold(
          (failure) {
            Helpers.showCustomDialogError(
              context: context,
              title: 'error'.tr,
              message: failure.data['message'] ?? 'error'.tr,
            );
          },
          (success) {
            Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);

            Helpers.showCustomDialogSuccess(
              context: context,
              title: 'success'.tr,
              message: 'passwordChangedSuccessfully'.tr,
            );
            Future.delayed(
              Duration(milliseconds: 2000),
              () {
                Get.back();
              },
            );
          },
        );
        isLoading(false);
      } else {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'PasswordsNotMatch'.tr,
        );
      }
    }
  }

  void toggleOldPasswordVisibility() {
    oldPasswordVisibility.value = !oldPasswordVisibility.value;
  }

  void toggleNewPasswordVisibility() {
    newPasswordVisibility.value = !newPasswordVisibility.value;
  }

  void toggleConfirmNewPasswordVisibility() {
    confirmNewPasswordVisibility.value = !confirmNewPasswordVisibility.value;
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
