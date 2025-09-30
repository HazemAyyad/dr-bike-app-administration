import 'package:doctorbike/features/admin/counters/data/repositories/countrers_implement.dart';
import 'package:get/get.dart';

import '../../../counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../data/repositories/boxes_implement.dart';
import '../../domain/usecases/add_box_balance_usecase.dart';
import '../../domain/usecases/add_boxes_usecase.dart';
import '../../domain/usecases/all_boxes_logs_usercase.dart';
import '../../domain/usecases/box_details_uesecase.dart';
import '../../domain/usecases/edit_box_usecase.dart';
import '../../domain/usecases/get_shown_box_usecase.dart';
import '../../domain/usecases/transfer_box_balance_usecase.dart';
import '../controllers/boxes_controller.dart';

class BoxesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BoxesController(
        boxesUsecase:
            AddBoxesUsecase(boxesRepository: Get.find<BoxesImplement>()),
        getShownBoxUsecase:
            GetShownBoxUsecase(boxesRepository: Get.find<BoxesImplement>()),
        allBoxesLogsUsecase:
            AllBoxesLogsUsercase(boxesRepository: Get.find<BoxesImplement>()),
        transferBoxBalanceUsecase: TransferBoxBalanceUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        boxDetailsUesecase: BoxDetailsUesecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        addBoxBalanceUsecase:
            AddBoxBalanceUsecase(boxesRepository: Get.find<BoxesImplement>()),
        editBoxUsecase:
            EditBoxUsecase(boxesRepository: Get.find<BoxesImplement>()),
        getReportByType: GetReportByTypeUsecase(
          countersRepository: Get.find<CountrersImplement>(),
        ),
      ),
    );
  }
}
