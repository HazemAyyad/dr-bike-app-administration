import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/api_error_message.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/native_biometric_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/notification_firebase_service.dart';
import '../../../../../core/services/session_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../../../employee/notifications/presentation/controllers/employee_notification_badge_controller.dart';
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
    _loadRememberMePreference();
    refreshBiometricLoginState();
  }

  Future<void> _loadRememberMePreference() async {
    isRemember.value = await UserData.getIsRememberUser();
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
    if (!enabled || !hasSavedData) {
      canShowBiometricLogin.value = false;
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final native = await NativeBiometricService.instance.isAvailable();
        canShowBiometricLogin.value = native.available;
        return;
      } catch (_) {
        // fall through to local_auth checks
      }
    }

    final supported = await service.isDeviceSupported();
    final canCheck = await service.canCheckBiometrics();
    final available = await service.getAvailableBiometrics();
    canShowBiometricLogin.value =
        supported && (canCheck || available.isNotEmpty);
  }

  void sendOtp(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    isLoading(true);
    try {
      final fcmToken =
          await NotificationFirebaseService.instance.resolveTokenForLogin();
      final result = await login.call(
        email: emailController.text,
        password: passwordController.text,
        fcmToken: fcmToken,
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

      final token = savedData.token!.trim();
      await UserData.saveToken(token);
      await UserData.saveUserJson(savedData.userDataJson!);
      await SessionService.hydrateToken();
      await _restoreSavedUserGlobals();

      final validation = await SessionService.validateAndRefreshSession();
      if (!validation.isValid) {
        if (validation.isAuthFailure) {
          await BiometricAuthService.instance.setBiometricLoginEnabled(false);
          await BiometricAuthService.instance.clearLoginData();
          canShowBiometricLogin.value = false;
        }
        await UserData.clearAllUserData();
        _showMessage(
          title: 'تنبيه',
          message: validation.isAuthFailure
              ? 'انتهت الجلسة على السيرفر (مثلاً بعد مسح الجلسات). سجّل دخولاً بكلمة المرور.'
              : 'تعذر التحقق من الجلسة. تحقق من الإنترنت وسجّل دخولاً بكلمة المرور.',
          isError: true,
        );
        return;
      }

      await BiometricAuthService.instance.saveCurrentSessionForBiometricLogin();

      try {
        await _registerAdminPushAfterLogin();
      } catch (e, st) {
        debugPrint('biometric login push setup error: $e\n$st');
      }
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
    await UserData.saveIsRememberUser(isRemember.value);

    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      userType = userdata.user.type;
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
      await NotificationFirebaseService.instance
          .syncFcmTokenToServer(source: 'login');
    }
    if (userType == 'admin') {
      if (!Get.isRegistered<AdminNotificationBadgeController>()) {
        Get.put(AdminNotificationBadgeController(), permanent: true);
      }
      await Get.find<AdminNotificationBadgeController>().refresh();
    } else if (userType == 'employee') {
      if (!Get.isRegistered<EmployeeNotificationBadgeController>()) {
        Get.put(EmployeeNotificationBadgeController(), permanent: true);
      }
      await Get.find<EmployeeNotificationBadgeController>().refresh();
    }
  }

  Future<void> _restoreSavedUserGlobals() async {
    final userdata = await UserData.getSavedUser();
    if (userdata == null) return;

    syncSessionIdentity(
      type: userdata.user.type,
      name: userdata.user.name,
      permissionIds:
          userdata.employeePermissions.map((p) => p.permissionId).toList(),
    );
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
