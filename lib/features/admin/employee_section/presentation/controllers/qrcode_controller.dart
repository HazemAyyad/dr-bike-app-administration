import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../domain/usecases/qr_scan_usecase.dart';

class QrCodeController extends GetxController {
  QrScanUsecase qrScanUsecase;
  QrCodeController({required this.qrScanUsecase});

  QRViewController? controller;

  Rx<Barcode?> scannedData = Rx<Barcode?>(null);

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      scannedData.value = scanData;
      controller.pauseCamera(); // إيقاف الكاميرا بعد المسح
    });
    update();
  }

  RxBool idQrCodeScan = false.obs;
  // QR Scan
  void qrScan(BuildContext context) async {
    idQrCodeScan(true);
    print(scannedData.value!.code!);
    final result = await qrScanUsecase.call(qrData: scannedData.value!.code!);
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        Get.back();
        Future.delayed(
          Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    idQrCodeScan(false);
  }
}
