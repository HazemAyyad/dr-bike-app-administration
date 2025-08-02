import 'dart:convert';
import 'package:doctorbike/core/services/final_classes.dart';

import '../../features/auth/data/models/user_model.dart';

class UserData {
  static String userToken = '';

  /// حفظ حالة تذكر المستخدم
  static Future<void> saveIsFirstTime(value) async {
    FinalClasses.getStorage.write('firstTime', value);
  }

  /// استرجاع حالة تذكر المستخدم
  static Future<bool> getIsFirstTime() async {
    return FinalClasses.getStorage.read('firstTime') ?? true;
  }

  /// حفظ الـ token
  static Future<void> saveToken(String token) async {
    await FinalClasses.secureStorage.write(key: 'token', value: token);
    UserData.userToken = token;
  }

  /// استرجاع الـ token
  static Future<String> getUserToken() async {
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
    await FinalClasses.secureStorage.write(key: 'userData', value: jsonString);
  }

  /// استرجاع بيانات المستخدم كاملة
  static Future<UserModel?> getSavedUser() async {
    final jsonString = await FinalClasses.secureStorage.read(key: 'userData');
    if (jsonString == null) return null;

    final jsonData = jsonDecode(jsonString);
    return UserModel.fromJson(jsonData);
  }

  /// حفظ حالة تذكر المستخدم
  static Future<void> saveIsRememberUser(value) async {
    FinalClasses.getStorage.write('isRemember', value);
  }

  /// استرجاع حالة تذكر المستخدم
  static Future<bool> getIsRememberUser() async {
    return FinalClasses.getStorage.read('isRemember') ?? false;
  }

  /// حذف كل البيانات المخزنة
  static Future<void> clearAllUserData() async {
    await FinalClasses.secureStorage.deleteAll();
    saveIsRememberUser(false);
    userToken = '';
  }
}
