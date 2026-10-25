import 'package:get/get.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/final_classes.dart';
import '../../data/sales_accounting_api_service.dart';
import '../controllers/sales_accounting_controller.dart';

class SalesAccountingBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureNetworkAndApi();
    Get.lazyPut(() => SalesAccountingApiService(api: Get.find<DioConsumer>()));
    Get.lazyPut(() {
      const key = 'sales_accounting_report_filters_v1';
      final saved = FinalClasses.getStorage.read(key);
      return SalesAccountingController(
        service: Get.find<SalesAccountingApiService>(),
        savedFilters: saved is Map ? Map<String, dynamic>.from(saved) : null,
        persistFilters: (filters) async {
          if (filters == null) {
            await FinalClasses.getStorage.remove(key);
          } else {
            await FinalClasses.getStorage.write(key, filters);
          }
        },
      );
    });
  }
}
