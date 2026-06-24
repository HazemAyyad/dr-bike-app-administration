import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/employee_attendance_persistent_notification_service.dart';
import '../../../employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../data/models/qr_scan_result.dart';
import '../../domain/usecases/qr_scan_usecase.dart';

class QrCodeController extends GetxController {
  QrCodeController({required this.qrScanUsecase});

  final QrScanUsecase qrScanUsecase;

  QRViewController? controller;

  Rx<Barcode?> scannedData = Rx<Barcode?>(null);

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool _scanInFlight = false;

  void onQRViewCreated(QRViewController controller) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_scanInFlight) return;
      scannedData.value = scanData;
      unawaited(qrScan());
      controller.pauseCamera();
    });
    update();
  }

  RxBool idQrCodeScan = false.obs;

  Future<void> qrScan() async {
    final code = scannedData.value?.code;
    if (code == null || code.isEmpty || _scanInFlight) return;

    _scanInFlight = true;
    idQrCodeScan(true);
    try {
      final result = await qrScanUsecase.call(qrData: code);
      await result.fold<Future<void>>(
        (failure) async {
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) async {
          final dashboard = Get.find<EmployeeDashbordController>();
          await dashboard.refreshTodayAttendance(silent: false);
          await _syncPersistentAfterScan(dashboard, success);

          Get.back();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          final extra = <String>[];
          if (success.workedHours != null) {
            extra.add('${'workedHoursLabel'.tr}: ${success.workedHours}');
          }
          if (success.overtimeHours != null) {
            extra.add('${'overtimeHoursLabel'.tr}: ${success.overtimeHours}');
          }
          if (success.totalSalary != null) {
            extra.add('${'totalSalaryLabel'.tr}: ${success.totalSalary}');
          }
          final msg = extra.isEmpty
              ? success.message
              : '${success.message}\n${extra.join('\n')}';

          Helpers.showCustomDialogSuccess(
            context: Get.context!,
            title: 'success'.tr,
            message: msg,
          );
        },
      );
    } finally {
      _scanInFlight = false;
      idQrCodeScan(false);
    }
  }

  Future<void> _syncPersistentAfterScan(
    EmployeeDashbordController dashboard,
    QrScanResult success,
  ) async {
    final inside = success.scan == 'in'
        ? true
        : success.scan == 'out'
            ? false
            : dashboard.isAttendanceInside;

    await EmployeeAttendancePersistentNotificationService.instance.sync(
      weeklyDaysOff: dashboard.employeeData.value?.weeklyDaysOff ?? const [],
      endWorkTime: dashboard.employeeData.value?.endWorkTime ?? '',
      isInside: inside,
    );
  }
}
