import 'dart:convert';

import 'package:doctorbike/core/services/final_classes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../features/auth/data/models/user_model.dart';
import 'initial_bindings.dart';

class UserData {
  static String userToken = '';
  static const String _tokenBackupKey = 'auth_token_backup';

  /// حفظ حالة تذكر المستخدم
  static Future<void> saveIsFirstTime(bool value) async {
    FinalClasses.getStorage.write('firstTime', value);
  }

  /// استرجاع حالة تذكر المستخدم
  static Future<bool> getIsFirstTime() async {
    return FinalClasses.getStorage.read('firstTime') ?? true;
  }

  /// حفظ الـ token (secure + نسخة احتياطية لضمان البقاء بعد إغلاق التطبيق)
  static Future<void> saveToken(String token) async {
    UserData.userToken = token;
    if (kIsWeb) {
      await FinalClasses.getStorage.write('token', token);
      return;
    }

    await FinalClasses.secureStorage.write(key: 'token', value: token);
    await FinalClasses.getStorage.write(_tokenBackupKey, token);
  }

  /// استرجاع الـ token
  static Future<String> getUserToken() async {
    if (kIsWeb) {
      final v = FinalClasses.getStorage.read('token');
      return v == null ? '' : v.toString();
    }

    var token = await FinalClasses.secureStorage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      final backup = FinalClasses.getStorage.read(_tokenBackupKey);
      token = backup == null ? '' : backup.toString();
      if (token.isNotEmpty) {
        await FinalClasses.secureStorage.write(key: 'token', value: token);
      }
    }
    return token;
  }

  /// حفظ بيانات المستخدم كاملة
  static Future<void> saveUser(UserModel response) async {
    final jsonString = jsonEncode(response.toJson());
    await saveUserJson(jsonString);
  }

  static Future<void> saveUserJson(String jsonString) async {
    if (kIsWeb) {
      await FinalClasses.getStorage.write('userData', jsonString);
    } else {
      await FinalClasses.secureStorage.write(key: 'userData', value: jsonString);
      await FinalClasses.getStorage.write('userData_backup', jsonString);
    }
  }

  /// استرجاع بيانات المستخدم كاملة
  static Future<UserModel?> getSavedUser() async {
    String? jsonString;
    if (kIsWeb) {
      jsonString = FinalClasses.getStorage.read('userData')?.toString();
    } else {
      jsonString = await FinalClasses.secureStorage.read(key: 'userData');
      if (jsonString == null || jsonString.isEmpty) {
        jsonString = FinalClasses.getStorage.read('userData_backup')?.toString();
        if (jsonString != null && jsonString.isNotEmpty) {
          await FinalClasses.secureStorage.write(
            key: 'userData',
            value: jsonString,
          );
        }
      }
    }
    if (jsonString == null || jsonString.isEmpty) return null;

    final jsonData = jsonDecode(jsonString);
    return UserModel.fromJson(Map<String, dynamic>.from(jsonData as Map));
  }

  /// حفظ حالة تذكر المستخدم
  static Future<void> saveIsRememberUser(bool value) async {
    FinalClasses.getStorage.write('isRemember', value);
  }

  /// استرجاع حالة تذكر المستخدم
  static Future<bool> getIsRememberUser() async {
    return FinalClasses.getStorage.read('isRemember') ?? false;
  }

  /// حذف كل البيانات المخزنة
  static Future<void> clearAllUserData() async {
    if (kIsWeb) {
      await FinalClasses.getStorage.remove('token');
      await FinalClasses.getStorage.remove('userData');
    } else {
      await FinalClasses.secureStorage.delete(key: 'token');
      await FinalClasses.secureStorage.delete(key: 'userData');
      await FinalClasses.getStorage.remove(_tokenBackupKey);
      await FinalClasses.getStorage.remove('userData_backup');
    }
    saveIsRememberUser(false);
    userToken = '';
    employeePermissions = [];
    userType = '';
    sessionUserType.value = '';
  }
}
