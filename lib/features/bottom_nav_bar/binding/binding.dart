import 'package:get/get.dart';

import '../controllers/bottom_nav_bar_controller.dart';

class BottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<BottomNavBarController>()) {
      return;
    }
    Get.put(BottomNavBarController(), permanent: true);
  }
}
