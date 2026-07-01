import 'package:get/get.dart';

import '../../data/meta_catalog_api_service.dart';
import '../controllers/meta_catalog_controller.dart';

class MetaCatalogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MetaCatalogApiService(), fenix: true);
    Get.lazyPut(() => MetaCatalogController(Get.find()));
  }
}
