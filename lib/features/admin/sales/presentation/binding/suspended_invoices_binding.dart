import 'package:get/get.dart';

import '../controllers/sales_controller.dart';
import '../controllers/suspended_invoices_controller.dart';
import 'sales_binding.dart';

class SuspendedInvoicesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SalesController>()) {
      SalesBinding().dependencies();
    }
    Get.lazyPut(() => SuspendedInvoicesController());
  }
}
