import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'final_classes.dart';
import 'native_biometric_service.dart';

class BiometricLoginData {
  const BiometricLoginData({
    this.token,
    this.userDataJson,
  });

  final String? token;
  final String? userDataJson;

  bool get hasToken => token != null && token!.isNotEmpty;
  bool get hasUserData => userDataJson != null && userDataJson!.isNotEmpty;
  bool get hasLoginData => hasToken && hasUserData;

  Map<String, dynamic> toJson() => {
        if (token != null) 'token': token,
        if (userDataJson != null) 'userDataJson': userDataJson,
      };

  factory BiometricLoginData.fromJson(Map<String, dynamic> json) {
    return BiometricLoginData(
      token: json['token']?.toString(),
      userDataJson: json['userDataJson']?.toString(),
    );
  }
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.success,
    this.message,
    this.cancelled = false,
  });

  final bool success;
  final String? message;
  final bool cancelled;
}

class BiometricReadinessResult {
  const BiometricReadinessResult({
    required this.ready,
    this.message,
  });

  final bool ready;
  final String? message;
}

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _authInProgress = false;

  static const _enabledKey = 'biometric_login_enabled';
  static const _loginDataKey = 'biometric_login_data';

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric isDeviceSupported PlatformException: code=${e.code} message=${e.message}',
      );
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric canCheckBiometrics PlatformException: code=${e.code} message=${e.message}',
      );
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric getAvailableBiometrics PlatformException: code=${e.code} message=${e.message}',
      );
      return const [];
    }
  }

  Future<BiometricReadinessResult> checkReadiness({
    bool requireCurrentSession = false,
  }) async {
    final token = await readCurrentToken();
    final userDataJson = await readCurrentUserData();

    debugPrint(
      'Biometric readiness: web=$kIsWeb tokenExists=${token.isNotEmpty} '
      'userDataExists=${userDataJson != null && userDataJson.isNotEmpty}',
    );

    if (kIsWeb) {
      return const BiometricReadinessResult(
        ready: false,
        message: 'الدخول بالبصمة غير متاح على الويب',
      );
    }

    if (requireCurrentSession &&
        (token.isEmpty || userDataJson == null || userDataJson.isEmpty)) {
      return const BiometricReadinessResult(
        ready: false,
        message: 'يرجى تسجيل الدخول مرة أخرى لتفعيل الدخول بالبصمة',
      );
    }

    if (_isAndroid) {
      try {
        final nativeAvailability =
            await NativeBiometricService.instance.isAvailable();
        debugPrint(
          'Native biometric availability: available=${nativeAvailability.available} '
          'code=${nativeAvailability.code} message=${nativeAvailability.message}',
        );
        if (!nativeAvailability.available) {
          return BiometricReadinessResult(
            ready: false,
            message: nativeAvailability.message ??
                'يرجى تفعيل البصمة أو قفل الشاشة من إعدادات الجهاز أولاً',
          );
        }
        return const BiometricReadinessResult(ready: true);
      } on MissingPluginException catch (e) {
        debugPrint('Native biometric availability missing plugin: $e');
      }
    }

    final supported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    final available = await getAvailableBiometrics();

    debugPrint(
      'Biometric readiness: isDeviceSupported=$supported '
      'canCheckBiometrics=$canCheck availableBiometrics=$available',
    );

    if (!supported) {
      return const BiometricReadinessResult(
        ready: false,
        message: 'جهازك لا يدعم البصمة أو التعرف على الوجه',
      );
    }

    if (!canCheck && available.isEmpty) {
      return const BiometricReadinessResult(
        ready: false,
        message: 'يرجى تفعيل البصمة أو الوجه أو قفل الشاشة من إعدادات الجهاز أولاً',
      );
    }

    return const BiometricReadinessResult(ready: true);
  }

  Future<BiometricAuthResult> authenticate({
    bool checkReadinessFirst = true,
    BuildContext? context,
    String source = 'unknown',
  }) async {
    if (_authInProgress) {
      debugPrint('Biometric auth: previous authentication is still active.');
      return const BiometricAuthResult(
        success: false,
        cancelled: true,
        message: 'عملية التحقق قيد التنفيذ',
      );
    }

    _authInProgress = true;
    try {
      _logUiDiagnostics(context: context, source: source);

      if (checkReadinessFirst) {
        final readiness = await checkReadiness();
        if (!readiness.ready) {
          return BiometricAuthResult(
            success: false,
            message: readiness.message,
          );
        }
      }

      if (_isAndroid) {
        try {
          debugPrint(
            'Biometric auth: starting native Android strongOrCredential authenticate.',
          );
          final nativeResult = await NativeBiometricService.instance.authenticate(
            method: 'authenticateStrongOrCredential',
          );
          debugPrint(
            'Biometric auth: native returned success=${nativeResult.success} '
            'available=${nativeResult.available} code=${nativeResult.code} '
            'codeText=${nativeResult.codeText} mode=${nativeResult.mode} '
            'message=${nativeResult.message}',
          );
          if (!nativeResult.success && nativeResult.code == -1001) {
            debugPrint(
              'Biometric auth: native prompt timed out; trying Keyguard fallback.',
            );
            final keyguardResult =
                await NativeBiometricService.instance.authenticate(
              method: 'authenticateKeyguard',
              timeout: const Duration(seconds: 180),
            );
            debugPrint(
              'Biometric auth: keyguard returned success=${keyguardResult.success} '
              'available=${keyguardResult.available} code=${keyguardResult.code} '
              'codeText=${keyguardResult.codeText} mode=${keyguardResult.mode} '
              'message=${keyguardResult.message}',
            );
            return BiometricAuthResult(
              success: keyguardResult.success,
              cancelled: !keyguardResult.success,
              message: keyguardResult.success
                  ? null
                  : keyguardResult.message ?? 'تم إلغاء عملية التحقق',
            );
          }
          return BiometricAuthResult(
            success: nativeResult.success,
            cancelled: !nativeResult.success,
            message: nativeResult.success
                ? null
                : nativeResult.message ?? 'تم إلغاء عملية التحقق',
          );
        } on MissingPluginException catch (e) {
          debugPrint('Biometric auth: native channel missing, fallback to local_auth: $e');
        }
      }

      return await _authenticateWithLocalAuth();
    } finally {
      _authInProgress = false;
    }
  }

  Future<BiometricAuthResult> _authenticateWithLocalAuth() async {
    try {
      final available = await getAvailableBiometrics();
      final forceBiometricOnly =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      debugPrint(
        'Biometric auth: platform=${kIsWeb ? 'web' : defaultTargetPlatform.name} '
        'androidSdk=unknown availableBiometrics=$available '
        'forceBiometricOnly=$forceBiometricOnly',
      );
      debugPrint('Biometric auth: starting local_auth authenticate.');

      final success = await _auth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك لتسجيل الدخول',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'تأكيد الهوية',
            cancelButton: 'إلغاء',
          ),
        ],
        biometricOnly: forceBiometricOnly,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () async {
          debugPrint('Biometric auth: timeout after 45 seconds.');
          await _stopPreviousAuthentication();
          throw TimeoutException('biometric_timeout');
        },
      );

      debugPrint('Biometric auth: authenticate returned success=$success.');
      return BiometricAuthResult(
        success: success,
        cancelled: !success,
        message: success ? null : 'تم إلغاء عملية التحقق',
      );
    } on TimeoutException catch (e) {
      debugPrint('Biometric auth TimeoutException: ${e.message}');
      await _stopPreviousAuthentication();
      return const BiometricAuthResult(
        success: false,
        cancelled: true,
        message:
            'لم تظهر نافذة البصمة أو انتهت المهلة، جرّب فتح قفل الجهاز ثم حاول مرة أخرى',
      );
    } on LocalAuthException catch (e) {
      debugPrint(
        'Biometric auth LocalAuthException: code=${e.code.name} '
        'message=${e.description}',
      );
      if (e.code == LocalAuthExceptionCode.authInProgress) {
        await _stopPreviousAuthentication();
      }
      return BiometricAuthResult(
        success: false,
        cancelled: e.code == LocalAuthExceptionCode.userCanceled ||
            e.code == LocalAuthExceptionCode.systemCanceled ||
            e.code == LocalAuthExceptionCode.timeout ||
            e.code == LocalAuthExceptionCode.userRequestedFallback,
        message: _messageForLocalAuthException(e),
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric auth PlatformException: code=${e.code} message=${e.message}',
      );
      return const BiometricAuthResult(
        success: false,
        cancelled: true,
        message: 'تعذر فتح نافذة البصمة، حاول مرة أخرى',
      );
    } catch (e) {
      debugPrint('Biometric auth unexpected error: $e');
      return const BiometricAuthResult(
        success: false,
        cancelled: true,
        message: 'تعذر فتح نافذة البصمة، حاول مرة أخرى',
      );
    }
  }

  Future<bool> isBiometricLoginEnabled() async {
    if (kIsWeb) return false;
    final value =
        await FinalClasses.secureStorage.read(key: _enabledKey) ?? 'false';
    return value == 'true';
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    if (kIsWeb) return;
    await FinalClasses.secureStorage.write(
      key: _enabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> saveLoginData({
    String? token,
    String? userDataJson,
  }) async {
    if (kIsWeb) return;
    final data = BiometricLoginData(
      token: token,
      userDataJson: userDataJson,
    );
    await FinalClasses.secureStorage.write(
      key: _loginDataKey,
      value: jsonEncode(data.toJson()),
    );
  }

  Future<void> saveCurrentSessionForBiometricLogin() async {
    final token = await readCurrentToken();
    final userDataJson = await readCurrentUserData();
    await saveLoginData(
      token: token.isEmpty ? null : token,
      userDataJson: userDataJson,
    );
  }

  Future<void> clearLoginData() async {
    if (kIsWeb) return;
    await FinalClasses.secureStorage.delete(key: _loginDataKey);
  }

  Future<BiometricLoginData?> getSavedLoginData() async {
    if (kIsWeb) return null;
    final jsonString = await FinalClasses.secureStorage.read(key: _loginDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final jsonData = jsonDecode(jsonString);
      if (jsonData is! Map) return null;
      final map = Map<String, dynamic>.from(jsonData);
      final oldPassword = map['password']?.toString() ?? '';
      if (oldPassword.isNotEmpty) {
        debugPrint(
          'Biometric login: old password-based data found and cleared.',
        );
        await setBiometricLoginEnabled(false);
        await clearLoginData();
        return null;
      }

      final data = BiometricLoginData.fromJson(map);
      return data.hasLoginData ? data : null;
    } catch (e) {
      debugPrint('Biometric login: failed to parse saved data: $e');
      return null;
    }
  }

  Future<bool> hasSavedLoginData() async {
    final data = await getSavedLoginData();
    return data != null && data.hasLoginData;
  }

  Future<String> readCurrentToken() async {
    if (kIsWeb) return '';
    return await FinalClasses.secureStorage.read(key: 'token') ?? '';
  }

  Future<String?> readCurrentUserData() async {
    if (kIsWeb) return null;
    return FinalClasses.secureStorage.read(key: 'userData');
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _logUiDiagnostics({
    required String source,
    BuildContext? context,
  }) {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    debugPrint(
      'Biometric auth UI diagnostics: source=$source '
      'lifecycle=$lifecycleState '
      'resumed=${lifecycleState == AppLifecycleState.resumed} '
      'contextMounted=${context?.mounted} currentRoute=${Get.currentRoute} '
      'dialogOpen=${Get.isDialogOpen} snackbarOpen=${Get.isSnackbarOpen} '
      'bottomSheetOpen=${Get.isBottomSheetOpen}',
    );
  }

  Future<void> _stopPreviousAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      debugPrint('Biometric stopAuthentication ignored: $e');
    }
  }

  String _messageForLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return 'جهازك لا يدعم البصمة أو التعرف على الوجه';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'يرجى تفعيل البصمة أو الوجه من إعدادات الجهاز أولاً';
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return 'محاولات كثيرة غير ناجحة، حاول لاحقاً';
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
        return 'تم إلغاء عملية التحقق';
      case LocalAuthExceptionCode.authInProgress:
        return 'يوجد تحقق بالبصمة قيد التشغيل بالفعل';
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        final message = e.description;
        if (message != null && message.trim().isNotEmpty) {
          return 'تعذر تشغيل البصمة: $message';
        }
        return 'تعذر فتح نافذة البصمة، حاول مرة أخرى';
      default:
        final message = e.description;
        if (message != null && message.trim().isNotEmpty) return message;
        return 'تعذر فتح نافذة البصمة، حاول مرة أخرى';
    }
  }
}
