import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';
import '../../sign_up/controllers/sign_up_controller.dart';

class SignUpOtpController extends GetxController {
  VerifyOtp verifyOtp;

  SignUpOtpController({required this.verifyOtp});

  final SignUpController signUpController = Get.find();

  RxString otpCode = ''.obs;

  RxInt secondsRemaining = 60.obs;

  Timer? timer;

  RxBool isLoading = false.obs;

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
      final result = await verifyOtp.call(
        email: signUpController.emailController.text,
        otpCode: otpCode.value,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: failure.data['errors'] ?? failure.errMessage);
        },
        (success) {
          Get.offAllNamed(AppRoutes.SIGNUPSUCCESSSCREEN);
        },
      );
      isLoading(false);
    } else {
      Get.snackbar(
        'error'.tr,
        'enterOtp'.tr,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
