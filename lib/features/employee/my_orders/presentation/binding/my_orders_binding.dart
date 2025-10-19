import 'package:doctorbike/features/employee/my_orders/data/repositories/common_repo_impl.dart';
import 'package:doctorbike/features/employee/my_orders/domain/usecases/get_my_orders_usecase.dart';
import 'package:get/get.dart';

import '../controllers/my_orders_controller.dart';

class MyOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => MyOrdersController(
        getMyOrdersUsecase: GetMyOrdersUsecase(
          myOrdersRepository: Get.find<MyOrdersImplement>(),
        ),
      ),
    );
  }
}
