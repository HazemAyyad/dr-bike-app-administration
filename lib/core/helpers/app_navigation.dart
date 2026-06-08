import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared GetX navigation helpers.
class AppNavigation {
  AppNavigation._();

  /// Pops until [routeName] is current. If it is not in the stack, opens it.
  static void popToRoute(String routeName) {
    final context = Get.context;
    if (context == null) {
      if (Get.currentRoute != routeName) {
        Get.offNamed(routeName);
      }
      return;
    }

    var found = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == routeName) {
        found = true;
        return true;
      }
      return route.isFirst;
    });

    if (!found && Get.currentRoute != routeName) {
      Get.offNamed(routeName);
    }
  }
}
