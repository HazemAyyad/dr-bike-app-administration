import 'package:doctorbike/features/admin/general_data_list/data/repositories/general_data_list_implement.dart';
import 'package:doctorbike/features/admin/general_data_list/domain/usecases/get_customers_usecase.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_serves.dart';
import 'package:get/get.dart';

import '../controllers/general_data_list_controller.dart';

class GeneralDataListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => GeneralDataListController(
        getCustomersUseCase: GetCustomersUseCase(
          generalDataListRepository: Get.find<GeneralDataListImplement>(),
        ),
        generalDataServes: Get.find<GeneralDataServes>(),
      ),
    );
  }
}
