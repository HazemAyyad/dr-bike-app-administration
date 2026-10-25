import 'package:get/get.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/final_classes.dart';
import '../../data/financial_accounting_api_service.dart';
import '../controllers/financial_accounting_controller.dart';

class FinancialAccountingBinding extends Bindings {
  FinancialAccountingBinding(this.type);
  final String type;
  @override
  void dependencies() {
    AppDependencyRegistry.ensureNetworkAndApi();
    if (!Get.isRegistered<FinancialAccountingApiService>() &&
        !Get.isPrepared<FinancialAccountingApiService>()) {
      Get.lazyPut(
          () => FinancialAccountingApiService(api: Get.find<DioConsumer>()),
          fenix: true);
    }
    Get.lazyPut(() {
      final key = 'financial_accounting_${type}_filters_v1';
      final saved = FinalClasses.getStorage.read(key);
      return FinancialAccountingController(
        service: Get.find<FinancialAccountingApiService>(),
        type: type,
        savedFilters: saved is Map ? Map<String, dynamic>.from(saved) : null,
        initialFilters: Get.arguments is Map
            ? Map<String, dynamic>.from(Get.arguments as Map)
            : null,
        persistFilters: (value) async {
          if (value == null) {
            await FinalClasses.getStorage.remove(key);
          } else {
            await FinalClasses.getStorage.write(key, value);
          }
        },
      );
    }, tag: type);
  }
}
