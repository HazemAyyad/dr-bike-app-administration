import 'package:get/get.dart';

import '../../data/whatsapp_api_service.dart';
import '../controllers/whatsapp_center_controller.dart';
import '../controllers/whatsapp_conversation_controller.dart';

class WhatsAppCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WhatsAppApiService(), fenix: true);
    Get.lazyPut(() => WhatsAppCenterController(Get.find()));
  }
}

class WhatsAppConversationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WhatsAppApiService(), fenix: true);
    Get.lazyPut(() => WhatsAppConversationController(Get.find()));
  }
}
