import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/api_error_message.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/final_classes.dart';
import '../../../../../core/services/initial_bindings.dart';
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
    canShowBiometricLogin.value =
        enabled && hasSavedData && supported && canCheck;
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
          await _handleSuccessfulNormalLogin(context);
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
          message: 'يرجى تسجيل الدخول بالطريقة العادية أولاً لتفعيل الدخول بالبصمة',
          isError: true,
        );
        return;
      }

      final authResult = await service.authenticate();
      if (!authResult.success) {
        _showMessage(
          title: 'تنبيه',
          message: authResult.message ?? 'تعذر تشغيل الدخول بالبصمة حالياً',
          isError: true,
        );
        return;
      }

      if (!savedData.hasCredentials && savedData.hasToken) {
        await UserData.saveToken(savedData.token!);
        if (savedData.userDataJson != null &&
            savedData.userDataJson!.isNotEmpty) {
          await FinalClasses.secureStorage.write(
            key: 'userData',
            value: savedData.userDataJson,
          );
        }
        await _restoreSavedUserGlobals();
        Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        return;
      }

      final result = await login.call(
        email: savedData.email,
        password: savedData.password,
        fcmToken: _currentFcmToken(),
      );

      await result.fold<Future<void>>(
        (failure) async {
          _showMessage(
            title: 'خطأ',
            message: userFacingMessageFromFailure(failure),
            isError: true,
          );
        },
        (success) async {
          await _saveCurrentLoginForBiometrics(
            email: savedData.email,
            password: savedData.password,
          );
          Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        },
      );
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

  Future<void> _handleSuccessfulNormalLogin(BuildContext context) async {
    if (isRemember.value) {
      await UserData.saveIsRememberUser(isRemember.value);
    }

    final service = BiometricAuthService.instance;
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!kIsWeb && await service.isBiometricLoginEnabled()) {
      await _saveCurrentLoginForBiometrics(email: email, password: password);
      Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
      return;
    }

    if (!kIsWeb && await service.isDeviceSupported()) {
      final shouldEnable = await _showEnableBiometricDialog();
      if (shouldEnable == true) {
        final enabled = await _enableBiometricLogin(email, password);
        if (enabled) {
          _showMessage(
            title: 'تم',
            message: 'تم تفعيل الدخول بالبصمة بنجاح',
          );
        }
      }
    }

    Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
  }

  Future<bool> _enableBiometricLogin(String email, String password) async {
    final service = BiometricAuthService.instance;

    if (!await service.isDeviceSupported()) {
      _showMessage(
        title: 'تنبيه',
        message: 'جهازك لا يدعم البصمة أو التعرف على الوجه',
        isError: true,
      );
      return false;
    }

    final canCheck = await service.canCheckBiometrics();
    final available = await service.getAvailableBiometrics();
    if (!canCheck || available.isEmpty) {
      _showMessage(
        title: 'تنبيه',
        message: 'يرجى تفعيل البصمة أو الوجه من إعدادات الجهاز أولاً',
        isError: true,
      );
      return false;
    }

    final authResult = await service.authenticate();
    if (!authResult.success) {
      _showMessage(
        title: 'تنبيه',
        message: authResult.message ?? 'تم إلغاء المصادقة بالبصمة',
        isError: true,
      );
      return false;
    }

    await _saveCurrentLoginForBiometrics(email: email, password: password);
    await service.setBiometricLoginEnabled(true);
    await refreshBiometricLoginState();
    return true;
  }

  Future<void> _saveCurrentLoginForBiometrics({
    required String email,
    required String password,
  }) async {
    final token = await UserData.getUserToken();
    final userDataJson = kIsWeb
        ? FinalClasses.getStorage.read('userData')?.toString()
        : await FinalClasses.secureStorage.read(key: 'userData');

    await BiometricAuthService.instance.saveLoginData(
      email: email.trim(),
      password: password,
      token: token.isEmpty ? null : token,
      userDataJson: userDataJson,
    );
  }

  Future<bool?> _showEnableBiometricDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('هل تريد تفعيل الدخول بالبصمة لهذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('تفعيل'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
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
