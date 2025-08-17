import 'package:get/get.dart';

import '../../data/repositorie_imp/employee_section_implement.dart';
import '../../domain/usecases/qr_scan_usecase.dart';
import '../controllers/qrcode_controller.dart';

class QrCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => QrCodeController(
        qrScanUsecase: QrScanUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
    );
  }
}
