import 'package:get/get.dart';

import '../../data/repositories/scan_qrcode_implement.dart';
import '../../domain/usecases/qr_scan_usecase.dart';
import '../controllers/qrcode_controller.dart';

class QrCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => QrCodeController(
        qrScanUsecase: QrScanUsecase(
          scanQrCodeRepository: Get.find<ScanQrCodeImplement>(),
        ),
      ),
    );
  }
}
