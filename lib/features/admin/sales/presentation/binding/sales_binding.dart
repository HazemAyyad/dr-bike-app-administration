import 'package:get/get.dart';

import '../controllers/sales_controller.dart';
import '../controllers/sales_service.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SalesController(
        salesService: SalesService(),
      ),
    );
  }
}
