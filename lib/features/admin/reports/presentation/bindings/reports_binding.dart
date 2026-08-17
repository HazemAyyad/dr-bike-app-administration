import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../data/reports_api_service.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureNetworkAndApi();
    if (!Get.isRegistered<ReportsApiService>() &&
        !Get.isPrepared<ReportsApiService>()) {
      Get.lazyPut(
        () => ReportsApiService(api: Get.find<DioConsumer>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ReportsController>() &&
        !Get.isPrepared<ReportsController>()) {
      Get.lazyPut(
        () => ReportsController(service: Get.find<ReportsApiService>()),
        fenix: true,
      );
    }
  }
}
