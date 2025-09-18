import 'package:get/get.dart';

import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../data/repositories/maintenance_implement.dart';
import '../../domain/usecases/creat_maintenance_usecase.dart';
import '../../domain/usecases/get_maintenances_details_usecase.dart';
import '../../domain/usecases/maintenance_usecase.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => MaintenanceController(
        maintenanceUsecase: MaintenanceUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        creatMaintenanceUsecase: CreatMaintenanceUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getMaintenancesDetailsUsecase: GetMaintenancesDetailsUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
      ),
    );
  }
}
