import 'package:get/get.dart';

import '../controllers/current_follow_up_controller.dart';

class CurrentFollowUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CurrentFollowUpController());
  }
}
