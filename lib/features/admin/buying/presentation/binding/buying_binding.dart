import 'package:get/get.dart';

import '../controllers/buying_controller.dart';

class BuyingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BuyingController());
  }
}
