import 'package:get/get.dart';

import '../../data/smart_home_api_service.dart';
import '../../data/smart_home_native_service.dart';
import '../controllers/smart_home_controller.dart';

class SmartHomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SmartHomeApiService>()) {
      Get.lazyPut<SmartHomeApiService>(() => SmartHomeApiService());
    }
    if (!Get.isRegistered<SmartHomeNativeService>()) {
      Get.lazyPut<SmartHomeNativeService>(() => SmartHomeNativeService());
    }
    Get.lazyPut<SmartHomeController>(
      () => SmartHomeController(
        apiService: Get.find<SmartHomeApiService>(),
        nativeService: Get.find<SmartHomeNativeService>(),
      ),
    );
  }
}
