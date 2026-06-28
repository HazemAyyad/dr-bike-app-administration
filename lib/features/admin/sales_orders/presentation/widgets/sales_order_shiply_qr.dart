import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_orders_controller.dart';

/// عرض رمز QR الخاص بطرد Shiply داخل نافذة منبثقة مع إمكانية التكبير والتحميل والطباعة.
class SalesOrderShiplyQr {
  static Future<void> show(BuildContext context, String code) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ShiplyQrDialog(code: code),
    );
  }
}

class _ShiplyQrDialog extends StatefulWidget {
  const _ShiplyQrDialog({required this.code});

  final String code;

  @override
  State<_ShiplyQrDialog> createState() => _ShiplyQrDialogState();
}

class _ShiplyQrDialogState extends State<_ShiplyQrDialog> {
  final GlobalKey _qrKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _captureQr() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) {
        SalesOrderShiplyQrNotice.error();
        return;
      }
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'shiply_qr_${widget.code}_${DateTime.now().millisecondsSinceEpoch}',
      );
      Get.snackbar('done'.tr, 'salesOrderShiplyQrSaved'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      SalesOrderShiplyQrNotice.error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: widget.code,
                  width: 220,
                  height: 220,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  widget.code,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (_) {
      SalesOrderShiplyQrNotice.error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: AppColors.primaryColor, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'salesOrderShiplyQrTitle'.tr,
                    style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, size: 22.sp, color: Colors.black54),
                  tooltip: 'salesOrderQrClose'.tr,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            RepaintBoundary(
              key: _qrKey,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: widget.code,
                        version: QrVersions.auto,
                        size: 240.sp,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        widget.code,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (_busy)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const CircularProgressIndicator(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _download,
                      icon: Icon(Icons.file_download_outlined, size: 20.sp),
                      label: Text('salesOrderQrDownload'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _print,
                      icon: Icon(Icons.print_outlined, size: 20.sp),
                      label: Text('salesOrderQrPrint'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SalesOrderShiplyQrNotice {
  static void error() {
    Get.snackbar(
      'error'.tr,
      'salesOrderShiplyQrSaveFailed'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
    );
  }
}

/// زر مختصر داخل بطاقة اللوجستيك يفتح نافذة رمز QR للطرد.
class SalesOrderShiplyQrTile extends StatelessWidget {
  const SalesOrderShiplyQrTile({Key? key, required this.code}) : super(key: key);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: InkWell(
        onTap: () => SalesOrderShiplyQr.show(context, code),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Icon(Icons.qr_code_2,
                  size: 18.sp, color: SalesOrdersController.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'salesOrderShiplyQrShow'.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18.sp, color: SalesOrdersController.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
