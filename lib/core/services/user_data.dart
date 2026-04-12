import 'dart:convert';

import 'package:doctorbike/core/services/final_classes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../features/auth/data/models/user_model.dart';
import 'initial_bindings.dart';

class UserData {
  static String userToken = '';

  /// حفظ حالة تذكر المستخدم
  static Future<void> saveIsFirstTime(bool value) async {
    FinalClasses.getStorage.write('firstTime', value);
  }

  /// استرجاع حالة تذكر المستخدم
  static Future<bool> getIsFirstTime() async {
    return FinalClasses.getStorage.read('firstTime') ?? true;
  }

  /// حفظ الـ token
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      await FinalClasses.getStorage.write('token', token);
    } else {
      await FinalClasses.secureStorage.write(key: 'token', value: token);
    }
    UserData.userToken = token;
  }

  /// استرجاع الـ token
  static Future<String> getUserToken() async {
    if (kIsWeb) {
      final v = FinalClasses.getStorage.read('token');
      return v == null ? '' : v.toString();
    }
    return await FinalClasses.secureStorage.read(key: 'token') ?? '';
  }

  /// استرجاع الـ token
  // static Future<void> getUserToken() async {
  //   final savedToken = await secureStorage.read(key: 'token');
  //   if (savedToken != null) {
  //     UserData.token = savedToken;
  //   }
  // }

  /// حفظ بيانات المستخدم كاملة
  static Future<void> saveUser(UserModel response) async {
    final jsonString = jsonEncode(response.toJson());
    if (kIsWeb) {
      await FinalClasses.getStorage.write('userData', jsonString);
    } else {
      await FinalClasses.secureStorage.write(key: 'userData', value: jsonString);
    }
  }

  /// استرجاع بيانات المستخدم كاملة
  static Future<UserModel?> getSavedUser() async {
    final String? jsonString = kIsWeb
        ? FinalClasses.getStorage.read('userData')?.toString()
        : await FinalClasses.secureStorage.read(key: 'userData');
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
      await FinalClasses.secureStorage.deleteAll();
    }
    saveIsRememberUser(false);
    userToken = '';
    employeePermissions = [];
    userType = '';
  }
}
