import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/api_error_message.dart';
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
    if (!formKey.currentState!.validate()) return;
    isLoading(true);
    try {
      final result = await login.call(
        email: emailController.text,
        password: passwordController.text,
        // على الويب لا نُهيّئ Firebase؛ قراءة FCM ترمي FirebaseException مع interop.
        fcmToken: kIsWeb
            ? 'no_token'
            : (NotificationFirebaseService.instance.finalToken.isEmpty
                ? 'no_token'
                : NotificationFirebaseService.instance.finalToken),
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: userFacingMessageFromFailure(failure),
          );
        },
        (success) {
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: 'loginSuccess'.tr,
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
    } catch (e, st) {
      debugPrint('login error: $e\n$st');
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: kIsWeb
            ? 'حدث خطأ أثناء تسجيل الدخول. تحقق من الاتصال والبيانات وحاول مرة أخرى.'
            : e.toString(),
      );
    } finally {
      isLoading(false);
    }
  }
}
