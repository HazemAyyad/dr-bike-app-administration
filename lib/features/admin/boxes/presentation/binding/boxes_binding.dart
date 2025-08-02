import 'package:get/get.dart';

import '../controllers/boxes_controller.dart';


class BoxesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BoxesController());
  }
}
