import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'final_classes.dart';

class ThemeService {
  static final String _storageKey = 'ThemeMode';

  static RxBool isDark =
      RxBool(FinalClasses.getStorage.read(_storageKey) ?? false);

  static ThemeService instance = ThemeService._();
  // ignore: empty_constructor_bodies
  ThemeService._() {}
  set themeMode(ThemeMode themeMode) {
    if (themeMode == ThemeMode.system) {
      FinalClasses.getStorage.remove(_storageKey);
    } else {
      FinalClasses.getStorage.write(_storageKey, themeMode == ThemeMode.dark);
    }
    Get.changeThemeMode(themeMode);
  }

  static void toggleTheme(bool isDarkMode) {
    isDark.value = isDarkMode;
    final mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    instance.themeMode = mode;
    Get.changeThemeMode(mode);
  }

  ThemeMode get themeMode {
    switch (FinalClasses.getStorage.read(_storageKey)) {
      case true:
        return ThemeMode.dark;
      case false:
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }
}
