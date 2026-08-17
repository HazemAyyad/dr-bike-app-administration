import 'package:get/get.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../data/reports_api_service.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ReportsApiService(api: Get.find<ApiConsumer>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ReportsController(service: Get.find<ReportsApiService>()),
    );
  }
}
