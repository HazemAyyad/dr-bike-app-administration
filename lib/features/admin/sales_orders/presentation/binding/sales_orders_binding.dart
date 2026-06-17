import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/features/admin/sales_orders/data/repositories/sales_orders_implement.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/controllers/sales_orders_controller.dart';
import 'package:get/get.dart';

class SalesOrdersBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureSalesOrders();
    Get.lazyPut(
      () => SalesOrdersController(
        repository: Get.find<SalesOrdersImplement>(),
      ),
      fenix: true,
    );
  }
}
