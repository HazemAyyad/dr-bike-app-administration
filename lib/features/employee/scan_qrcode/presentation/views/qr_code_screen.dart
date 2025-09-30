import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/screen_util_new.dart';
import '../controllers/qrcode_controller.dart';

class FullScreenQRScanner extends GetView<QrCodeController> {
  const FullScreenQRScanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Scan QR Code', action: false),
      body: Stack(
        children: [
          // BackdropFilter(
          //   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          //   child: Container(color: Color.fromRGBO(0, 0, 0, 0.01)),
          // ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 20.h),
              Center(
                child: SizedBox(
                  width: ScreenUtilNew.width(266),
                  height: ScreenUtilNew.height(266),
                  child: QRView(
                    key: controller.qrKey,
                    onQRViewCreated: controller.onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: AppColors.primaryColor,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.controller?.resumeCamera();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(10.w),
                ),
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
