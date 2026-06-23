import 'package:get/get.dart';

import '../../../../../routes/app_routes.dart';
import '../controllers/sales_orders_controller.dart';

/// True while the user is on the sales-order product picker or checkout.
class SalesOrderStockContext {
  static bool get isActive {
    if (!Get.isRegistered<SalesOrdersController>()) return false;
    final route = Get.currentRoute;
    return route == AppRoutes.NEWSALESORDERSCREEN ||
        route == AppRoutes.SALESORDERCHECKOUTSCREEN;
  }

  static SalesOrdersController? get controller =>
      isActive ? Get.find<SalesOrdersController>() : null;
}
