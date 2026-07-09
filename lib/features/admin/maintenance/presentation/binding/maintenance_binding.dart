import 'package:get/get.dart';

import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../data/repositories/maintenance_implement.dart';
import '../../domain/usecases/creat_maintenance_usecase.dart';
import '../../domain/usecases/deliver_maintenance_usecase.dart';
import '../../domain/usecases/get_maintenance_activity_log_usecase.dart';
import '../../domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../domain/usecases/get_maintenances_details_usecase.dart';
import '../../domain/usecases/maintenance_usecase.dart';
import '../../domain/usecases/sync_maintenance_products_usecase.dart';
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
        syncMaintenanceProductsUsecase: SyncMaintenanceProductsUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        deliverMaintenanceUsecase: DeliverMaintenanceUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        getMaintenanceActivityLogUsecase: GetMaintenanceActivityLogUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        getMaintenanceInvoiceUsecase: GetMaintenanceInvoiceUsecase(
          maintenanceRepository: Get.find<MaintenanceImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
      ),
    );
  }
}
