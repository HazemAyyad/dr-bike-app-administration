import 'package:doctorbike/features/admin/checks/data/repositories/checks_implement.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:get/get.dart';

import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/repositories/payment_implement.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PaymentController(
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        addPaymentUsecase:
            AddPaymentUsecase(paymentRepository: Get.find<PaymentImplement>()),
      ),
      fenix: true,
    );
  }
}
