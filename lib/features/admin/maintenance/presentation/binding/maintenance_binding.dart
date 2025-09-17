import 'package:get/get.dart';

import '../../data/repositories/maintenance_implement.dart';
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
      ),
    );
  }
}
