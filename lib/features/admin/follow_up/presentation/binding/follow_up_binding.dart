import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_all_products_usecase.dart';
import 'package:get/get.dart';

import '../../../checks/data/repositories/checks_implement.dart';
import '../../../sales/data/repositories/sales_implement.dart';
import '../../data/repositories/followup_implement.dart';
import '../../domain/usecases/add_followup_usecase.dart';
import '../../domain/usecases/add_new_follow_customer_usecase.dart';
import '../../domain/usecases/followup_details_cancel_usecase.dart';
import '../../domain/usecases/get_followup_usecase.dart';
import '../controllers/follow_up_controller.dart';

class FollowUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FollowUpController(
        getFollowupUsecase: GetFollowupUsecase(
          followupRepository: Get.find<FollowupImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        addFollowupUsecase: AddFollowupUsecase(
          followupRepository: Get.find<FollowupImplement>(),
        ),
        followupDetailsCancelUsecase: FollowupDetailsCancelUsecase(
          followupRepository: Get.find<FollowupImplement>(),
        ),
        addNewFollowCustomerUsecase: AddNewFollowCustomerUsecase(
          followupRepository: Get.find<FollowupImplement>(),
        ),
      ),
    );
  }
}
