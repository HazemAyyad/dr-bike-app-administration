import 'package:get/get.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../data/sales_returns_api_service.dart';
import '../controllers/sales_returns_controller.dart';

class SalesReturnsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
        () => SalesReturnsController(
            SalesReturnsApiService(Get.find<DioConsumer>())),
        fenix: true);
  }
}
