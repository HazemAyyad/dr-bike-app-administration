import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../domain/usecases/qr_scan_usecase.dart';

class QrCodeController extends GetxController {
  QrScanUsecase qrScanUsecase;
  QrCodeController({required this.qrScanUsecase});

  QRViewController? controller;

  Rx<Barcode?> scannedData = Rx<Barcode?>(null);

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void onQRViewCreated(QRViewController controller) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      scannedData.value = scanData;
      qrScan();
      controller.pauseCamera(); // إيقاف الكاميرا بعد المسح
    });
    update();
  }

  RxBool idQrCodeScan = false.obs;
  // QR Scan
  void qrScan() async {
    idQrCodeScan(true);
    final result = await qrScanUsecase.call(qrData: scannedData.value!.code!);
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: Get.context!,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        if (Get.find<EmployeeDashbordController>().isStartWork) {
          Get.find<EmployeeDashbordController>().onResetWork();
        } else {
          Get.find<EmployeeDashbordController>().onStartWork();
        }
        Get.back();
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            Get.back();
          },
        );
        Helpers.showCustomDialogSuccess(
          context: Get.context!,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    idQrCodeScan(false);
  }
}
