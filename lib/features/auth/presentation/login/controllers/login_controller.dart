import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/api_error_message.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/notification_firebase_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../../domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  Login login;
  LoginController({required this.login});

  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final isRemember = ValueNotifier(false);

  RxBool isLoading = false.obs;

  RxBool isBiometricLoading = false.obs;

  RxBool canShowBiometricLogin = false.obs;

  RxBool isPasswordVisible = true.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onInit() {
    super.onInit();
    refreshBiometricLoginState();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> refreshBiometricLoginState() async {
    if (kIsWeb) {
      canShowBiometricLogin.value = false;
      return;
    }

    final service = BiometricAuthService.instance;
    final enabled = await service.isBiometricLoginEnabled();
    final hasSavedData = await service.hasSavedLoginData();
    final supported = await service.isDeviceSupported();
    final canCheck = await service.canCheckBiometrics();
    final available = await service.getAvailableBiometrics();
    canShowBiometricLogin.value =
        enabled && hasSavedData && supported && canCheck && available.isNotEmpty;
  }

  void sendOtp(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    isLoading(true);
    try {
      final result = await login.call(
        email: emailController.text,
        password: passwordController.text,
        fcmToken: _currentFcmToken(),
      );
      await result.fold<Future<void>>(
        (failure) async {
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: userFacingMessageFromFailure(failure),
          );
        },
        (success) async {
          await _handleSuccessfulNormalLogin();
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

  Future<void> biometricLogin(BuildContext context) async {
    if (kIsWeb || isBiometricLoading.value) return;

    isBiometricLoading(true);
    try {
      final service = BiometricAuthService.instance;
      final savedData = await service.getSavedLoginData();
      if (savedData == null || !savedData.hasLoginData) {
        await service.setBiometricLoginEnabled(false);
        await service.clearLoginData();
        canShowBiometricLogin.value = false;
        _showMessage(
          title: 'تنبيه',
          message: 'انتهت صلاحية بيانات الدخول بالبصمة، يرجى تسجيل الدخول مرة أخرى',
          isError: true,
        );
        return;
      }

      final authResult = await service.authenticate(
        context: context,
        source: 'login_biometric_button',
      );
      if (!authResult.success) {
        _showMessage(
          title: 'تنبيه',
          message: authResult.message ?? 'تم إلغاء عملية التحقق',
          isError: true,
        );
        return;
      }

      await UserData.saveToken(savedData.token!);
      await UserData.saveUserJson(savedData.userDataJson!);
      await _restoreSavedUserGlobals();
      await _registerAdminPushAfterLogin();
      Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
    } catch (e, st) {
      debugPrint('biometric login error: $e\n$st');
      _showMessage(
        title: 'خطأ',
        message: 'تعذر إكمال الدخول بالبصمة حالياً',
        isError: true,
      );
    } finally {
      isBiometricLoading(false);
    }
  }

  Future<void> _handleSuccessfulNormalLogin() async {
    if (isRemember.value) {
      await UserData.saveIsRememberUser(isRemember.value);
    }

    if (!kIsWeb &&
        await BiometricAuthService.instance.isBiometricLoginEnabled()) {
      final savedData = await BiometricAuthService.instance.getSavedLoginData();
      if (savedData != null) {
        await BiometricAuthService.instance
            .saveCurrentSessionForBiometricLogin();
      }
    }

    await _registerAdminPushAfterLogin();

    Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
  }

  Future<void> _registerAdminPushAfterLogin() async {
    if (!kIsWeb) {
      await NotificationFirebaseService.instance.ensureInitialized();
    }
    if (!Get.isRegistered<AdminNotificationBadgeController>()) {
      Get.put(AdminNotificationBadgeController(), permanent: true);
    }
    await NotificationFirebaseService.instance
        .registerAdminDeviceTokenIfReady(source: 'login');
    if (Get.isRegistered<AdminNotificationBadgeController>()) {
      await Get.find<AdminNotificationBadgeController>().refresh();
    }
  }

  String _currentFcmToken() {
    return kIsWeb
        ? 'no_token'
        : (NotificationFirebaseService.instance.finalToken.isEmpty
            ? 'no_token'
            : NotificationFirebaseService.instance.finalToken);
  }

  Future<void> _restoreSavedUserGlobals() async {
    final userdata = await UserData.getSavedUser();
    if (userdata == null) return;

    employeePermissions
      ..clear()
      ..addAll(userdata.employeePermissions.map((p) => p.permissionId));
    userType = userdata.user.type;
  }

  void _showMessage({
    required String title,
    required String message,
    bool isError = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
    );
  }
}
