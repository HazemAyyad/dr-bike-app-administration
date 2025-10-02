import 'package:doctorbike/features/admin/boxes/data/repositories/boxes_implement.dart';
import 'package:doctorbike/features/admin/boxes/domain/usecases/get_shown_box_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/chash_to_box_usecase.dart';
import 'package:get/get.dart';

import '../../data/repositories/checks_implement.dart';
import '../../domain/usecases/add_checks_usecase.dart';
import '../../domain/usecases/all_customers_sellers_usecase.dart';
import '../../domain/usecases/cashed_to_person_cancel_usecase.dart';
import '../../domain/usecases/edit_checks_usecase.dart';
import '../../domain/usecases/general_checks_data_usecase.dart';
import '../../domain/usecases/general_outgoing_data_usecase.dart';
import '../../domain/usecases/get_checks_usecase.dart';
import '../../domain/usecases/return_check_usercase.dart';
import '../controllers/checks_controller.dart';

class ChecksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ChecksController(
        addChecksUsecase: AddChecksUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getChecksUsecase: GetChecksUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        generalChecksDataUsecase: GeneralChecksDataUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        cashedToPersonCancelUsecase: CashedToPersonOrCashedUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        generalOutgoingDataUsecase: GeneralOutgoingDataUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        returnCheckUsercase: ReturnCheckUsercase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        chashToBoxUsecase: ChashToBoxUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        editChecksUsecase: EditChecksUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
      ),
    );
  }
}
