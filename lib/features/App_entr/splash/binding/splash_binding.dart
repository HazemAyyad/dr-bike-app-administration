import 'package:get/get.dart';

import '../controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // put وليس lazyPut — وإلا onReady لا يُستدعى إذا لم يُستخدم controller في build
    Get.put<SplashController>(SplashController());
  }
}
