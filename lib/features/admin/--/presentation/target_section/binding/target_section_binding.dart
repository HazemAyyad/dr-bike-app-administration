import 'package:get/get.dart';

import '../controllers/target_section_controller.dart';

class TargetSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TargetSectionController());
  }
}
