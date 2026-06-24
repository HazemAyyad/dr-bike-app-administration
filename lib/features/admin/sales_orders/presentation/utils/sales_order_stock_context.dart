import 'package:get/get.dart';

import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/sales_orders_controller.dart';

/// True while reserved-stock UI should be active (picker / checkout).
class SalesOrderStockContext {
  static bool get isActive {
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>();
      if (sales.pickerReservedStockEnabled.value ||
          sales.salesOrderStockMode.value) {
        return true;
      }
    }

    final route = Get.currentRoute;
    return route == AppRoutes.NEWSALESORDERSCREEN ||
        route == AppRoutes.SALESORDERCHECKOUTSCREEN ||
        route == AppRoutes.INSTANTSALEPRODUCTPICKER;
  }

  static SalesOrdersController? get controller {
    if (!isActive) return null;
    if (!Get.isRegistered<SalesOrdersController>() &&
        !Get.isPrepared<SalesOrdersController>()) {
      return null;
    }
    return Get.find<SalesOrdersController>();
  }
}
