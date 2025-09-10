import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/notification_firebase_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  Login login;
  LoginController({required this.login});

  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final isRemember = ValueNotifier(false);

  RxBool isLoading = false.obs;

  RxBool isPasswordVisible = true.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void sendOtp(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await login.call(
        email: emailController.text,
        password: passwordController.text,
        fcmToken: NotificationFirebaseService.instance.finalToken,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: failure.data['message'].toString(),
          );
        },
        (success) {
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: 'success'.tr,
          );
          Future.delayed(
            const Duration(milliseconds: 1500),
            () {
              if (isRemember.value) {
                UserData.saveIsRememberUser(isRemember.value);
              }
              Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
            },
          );
        },
      );
      isLoading(false);
    }
  }
}
