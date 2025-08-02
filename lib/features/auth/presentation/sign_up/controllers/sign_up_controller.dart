import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../domain/usecases/register_usecase.dart';

class SignUpController extends GetxController {
  final formKey = GlobalKey<FormState>();

  Register registerCase;
  SignUpController({required this.registerCase});

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  final obscurePassword = ValueNotifier(true);

  final RxBool isLoading = false.obs;

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  void register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (passwordController.text == confirmPasswordController.text) {
        isLoading(true);
        final result = await registerCase.call(
          name: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        );
        result.fold(
          (failure) {
            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: failure.data['errors']
                  .toString()
                  .split('{')[1]
                  .split('}')[0]
                  .split('[')[1]
                  .split(']')[0],
            );
          },
          (success) {
            Get.toNamed(AppRoutes.SIGNUPVERIFYSCREEN);
          },
        );
        isLoading(false);
      } else {
        Helpers.showCustomDialogSecondaryError(
          context: context,
          title: "error".tr,
          message: "PasswordsNotMatch".tr,
        );
      }
    }
  }
}
