import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/helpers/media_permissions.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../admin/whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import '../utils/signature_image_processor.dart';

class EmployeeSignatureCapture {
  const EmployeeSignatureCapture({
    required this.originalBytes,
    required this.processedBytes,
    required this.source,
  });

  final Uint8List originalBytes;
  final Uint8List processedBytes;
  final String source;
}

Future<EmployeeSignatureCapture?> showEmployeeSignatureCapture(
  BuildContext context,
) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(
            title: Text('إضافة توقيع',
                style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle:
                Text('اختر الطريقة المناسبة وسيتم تفريغ الخلفية تلقائيًا'),
          ),
          _SourceTile(
            icon: Icons.draw_rounded,
            title: 'توقيع يدوي',
            subtitle: 'وقّع بإصبعك داخل التطبيق',
            onTap: () => Navigator.pop(context, 'manual'),
          ),
          _SourceTile(
            icon: Icons.camera_alt_rounded,
            title: 'تصوير التوقيع',
            subtitle: 'صوّر توقيعك على ورقة بيضاء',
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          _SourceTile(
            icon: Icons.upload_file_rounded,
            title: 'رفع صورة',
            subtitle: 'اختر صورة توقيع محفوظة على الجهاز',
            onTap: () => Navigator.pop(context, 'upload'),
          ),
        ]),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  Uint8List? original;
  if (source == 'manual') {
    original = await _manualSignature(context);
  } else if (source == 'camera') {
    if (!await ensureCameraPermission()) {
      showMediaPermissionDeniedSnackbar();
      return null;
    }
    final capture = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(allowVideo: false),
    );
    if (capture != null) original = await File(capture.path).readAsBytes();
  } else {
    if (!await ensurePhotosPermission()) {
      showMediaPermissionDeniedSnackbar();
      return null;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) original = await file.readAsBytes();
  }
  if (original == null || original.isEmpty || !context.mounted) return null;

  Uint8List processed;
  try {
    Get.dialog<void>(
      const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      barrierDismissible: false,
    );
    processed = await processSignatureImage(original);
  } catch (error) {
    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar('تعذر تجهيز التوقيع', '$error');
    return null;
  }
  if (Get.isDialogOpen ?? false) Get.back();
  if (!context.mounted) return null;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('معاينة التوقيع المفرغ'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('تأكد أن التوقيع واضح وكامل قبل اعتماده.'),
        SizedBox(height: 12.h),
        Container(
          height: 150.h,
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Image.memory(processed, fit: BoxFit.contain),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إعادة المحاولة'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('اعتماد المعاينة'),
        ),
      ],
    ),
  );
  if (accepted != true) return null;
  return EmployeeSignatureCapture(
    originalBytes: original,
    processedBytes: processed,
    source: source,
  );
}

Future<Uint8List?> _manualSignature(BuildContext context) async {
  final key = GlobalKey();
  final strokes = <List<Offset>>[].obs;
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('التوقيع اليدوي'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('وقّع داخل المساحة البيضاء بإصبعك.'),
          SizedBox(height: 10.h),
          RepaintBoundary(
            key: key,
            child: Container(
              height: 190.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.operationalPurple),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (event) => strokes.add([event.localPosition]),
                onPanUpdate: (event) {
                  if (strokes.isEmpty) return;
                  strokes.last.add(event.localPosition);
                  strokes.refresh();
                },
                child: Obx(() => CustomPaint(
                      painter: _SignaturePainter(
                        strokes.map((line) => List<Offset>.from(line)).toList(),
                      ),
                      child: const SizedBox.expand(),
                    )),
              ),
            ),
          ),
          Obx(() => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: strokes.isEmpty ? null : strokes.clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('مسح'),
                ),
              )),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () async {
            if (strokes.isEmpty || strokes.every((line) => line.length < 2)) {
              Get.snackbar('التوقيع مطلوب', 'وقّع داخل المربع أولاً');
              return;
            }
            final boundary = key.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
            final image = await boundary?.toImage(pixelRatio: 2.5);
            final data =
                await image?.toByteData(format: ui.ImageByteFormat.png);
            if (data != null && context.mounted) {
              Navigator.pop(context, data.buffer.asUint8List());
            }
          },
          child: const Text('متابعة'),
        ),
      ],
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.operationalCardBorder),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppColors.operationalPurple.withValues(alpha: .1),
            child: Icon(icon, color: AppColors.operationalPurple),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      );
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF17213A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var index = 1; index < stroke.length; index++) {
        path.lineTo(stroke[index].dx, stroke[index].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
