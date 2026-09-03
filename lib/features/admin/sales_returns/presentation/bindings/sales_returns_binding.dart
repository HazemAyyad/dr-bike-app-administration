import 'package:get/get.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../data/sales_returns_api_service.dart';
import '../controllers/sales_returns_controller.dart';

class SalesReturnsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<SalesReturnsController>() ||
        Get.isPrepared<SalesReturnsController>()) {
      return;
    }
    Get.lazyPut(
      () => SalesReturnsController(
        SalesReturnsApiService(Get.find<DioConsumer>()),
      ),
      fenix: true,
    );
  }
}
