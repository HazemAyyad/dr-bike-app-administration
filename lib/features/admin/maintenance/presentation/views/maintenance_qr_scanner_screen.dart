import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';

class MaintenanceQrPayload {
  MaintenanceQrPayload._();

  static int? maintenanceId(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.scheme.toLowerCase() == 'doctorbike' &&
        uri.host.toLowerCase() == 'maintenance') {
      final segments = uri.pathSegments;
      final idValue = segments.isNotEmpty && segments.first == 'invoice'
          ? (segments.length > 1 ? segments[1] : null)
          : (segments.isNotEmpty ? segments.first : null);
      return int.tryParse(idValue ?? '');
    }

    final match = RegExp(
      r'(?:maintenance(?:/invoice)?[:/#-]*)(\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    return int.tryParse(match?.group(1) ?? '');
  }
}

class MaintenanceQrScannerScreen extends StatefulWidget {
  const MaintenanceQrScannerScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceQrScannerScreen> createState() =>
      _MaintenanceQrScannerScreenState();
}

class _MaintenanceQrScannerScreenState
    extends State<MaintenanceQrScannerScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'maintenanceQr');
  QRViewController? _controller;
  StreamSubscription<Barcode>? _subscription;
  bool _handled = false;

  @override
  void reassemble() {
    super.reassemble();
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  Future<void> _onCreated(QRViewController controller) async {
    _controller = controller;
    var permission = await Permission.camera.status;
    if (!permission.isGranted) {
      permission = await Permission.camera.request();
    }
    if (!permission.isGranted) {
      if (mounted) {
        Get.snackbar('تنبيه', 'يجب السماح باستخدام الكاميرا لمسح رمز الصيانة');
      }
      return;
    }

    _subscription = controller.scannedDataStream.listen((barcode) async {
      final code = barcode.code?.trim();
      if (_handled || code == null || code.isEmpty) return;
      _handled = true;
      await controller.pauseCamera();
      if (!mounted) return;
      Navigator.of(context).pop(code);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'مسح فاتورة صيانة',
        action: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: QRView(
                  key: _qrKey,
                  onQRViewCreated: _onCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: AppColors.primaryColor,
                    borderRadius: 12.r,
                    borderLength: 34.w,
                    borderWidth: 8.w,
                    cutOutSize: 260.w,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
            child: Text(
              'وجّه الكاميرا نحو رمز QR الموجود أعلى فاتورة الصيانة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
