import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';
import '../../sgin_up_verify/controllers/sginup_verify_controller.dart';


import '../../../../../core/helpers/app_failure_notice.dart';
class ForgotPasswordController extends GetxController {
  VerifyOtp verifyOtp;

  ForgotPasswordController({required this.verifyOtp});

  RxString otpCode = ''.obs;

  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmationController =
      TextEditingController();

  RxInt secondsRemaining = 60.obs;

  Timer? timer;

  RxBool isLoading = false.obs;

  RxBool isPasswordVisible = true.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onInit() {
    startTimer();
    super.onInit();
  }

  void startTimer() {
    timer?.cancel();
    secondsRemaining.value = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        t.cancel();
      }
    });
  }

  void resendCode() {
    // إعادة إرسال الكود هنا
    startTimer();
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }

  void sendOtp(BuildContext context) async {
    if (otpCode.value.length == 4) {
      isLoading(true);
      if (passwordController.text == passwordConfirmationController.text) {
        final result = await verifyOtp.call(
          email: emailController.text,
          otpCode: otpCode.value,
          password: passwordController.text,
        );
        result.fold(
          (failure) {
            final errors = failure.data['errors'];
            String errorMessage = '';

            if (errors is Map) {
              errorMessage = errors.entries
                  .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                  .join("\n");
            } else {
              errorMessage = errors.toString();
            }
            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: errorMessage,
            );
          },
          (success) {
            Get.offAllNamed(AppRoutes.SIGNUPSUCCESSSCREEN);
          },
        );
        isLoading(false);
      } else {
        AppFailureNotice.show(
          title: 'error'.tr,
          message: 'enterOtp'.tr,
        );
      }
    }
  }
}
