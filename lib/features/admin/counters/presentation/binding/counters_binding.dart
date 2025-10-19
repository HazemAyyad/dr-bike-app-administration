import 'package:doctorbike/features/admin/counters/domain/usecases/get_report_information_usecase.dart';
import 'package:get/get.dart';

import '../../data/repositories/countrers_implement.dart';
import '../../domain/usecases/get_report_by_type_usecase.dart';
import '../controllers/counters_controller.dart';

class CountersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CountersController(
        getReportInformationUsecase: GetReportInformationUsecase(
          countersRepository: Get.find<CountrersImplement>(),
        ),
        getReportByType: GetReportByTypeUsecase(
          countersRepository: Get.find<CountrersImplement>(),
        ),
      ),
    );
  }
}
