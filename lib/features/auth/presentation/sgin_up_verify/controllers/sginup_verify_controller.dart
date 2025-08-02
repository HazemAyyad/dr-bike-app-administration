import 'package:doctorbike/features/auth/presentation/sign_up/controllers/sign_up_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../domain/usecases/send_otp_to_email_usecase.dart';

class SginupVerifyController extends GetxController {
  final formKey = GlobalKey<FormState>();

  SendOtpToEmail sendOtpToEmail;
  SginupVerifyController({required this.sendOtpToEmail});

  final SignUpController signUpController = Get.find();

  RxBool isEditing = false.obs;

  RxBool isFormValid = true.obs;

  RxBool isLoading = false.obs;

  void toggleEditing() {
    isEditing.value = !isEditing.value;
    if (!formKey.currentState!.validate() && isFormValid.value) {
      isFormValid.value = !isFormValid.value;
    }
  }

  void sendOtp(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isFormValid(true);
      isLoading(true);
      final result = await sendOtpToEmail.call(
        email: signUpController.emailController.text,
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
          Get.offNamed(AppRoutes.SIGNUPOTPSCREEN);
        },
      );
      isLoading(false);
    } else {
      isFormValid(false);
    }
  }
}
