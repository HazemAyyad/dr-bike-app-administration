import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../data/reports_api_service.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureNetworkAndApi();
    Get.lazyPut(
      () => ReportsApiService(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ReportsController(service: Get.find<ReportsApiService>()),
    );
  }
}
