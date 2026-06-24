import 'dart:ui';
import 'package:doctorbike/core/services/app_home_widget_service.dart';
import 'package:doctorbike/core/services/app_shortcut_service.dart';
import 'package:doctorbike/core/services/final_classes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  var currentLocale = 'ar'.obs;

  @override
  void onInit() {
    super.onInit();
    currentLocale.value = getLang();
    Get.updateLocale(Locale(currentLocale.value));
  }

  void changeLanguage(String languageCode) {
    // Update the observable value
    currentLocale.value = languageCode;

    // Update the app's locale using GetX
    Get.updateLocale(Locale(languageCode));

    // Persist the selected language
    setLang(languageCode);
    AppShortcutService.instance.refreshShortcutItems();
    AppHomeWidgetService.instance.syncPresentation();
    Get.back();
  }

  String getLang() {
    return FinalClasses.getStorage.read<String>('lang') ?? 'ar';
  }

  void setLang(String languageCode) {
    FinalClasses.getStorage.write('lang', languageCode);
  }
}
