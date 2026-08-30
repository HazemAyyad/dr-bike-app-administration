import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../binding/employee_dashbord_binding.dart';
import '../controllers/employee_salary_receipt_controller.dart';
import '../../../../../routes/app_routes.dart';

class EmployeeSalaryReceiptAlert
    extends GetView<EmployeeSalaryReceiptController> {
  const EmployeeSalaryReceiptAlert({Key? key}) : super(key: key);

  @override
  EmployeeSalaryReceiptController get controller {
    EmployeeDashbordBinding.ensureSalaryReceiptController();
    return Get.find<EmployeeSalaryReceiptController>();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        if (controller.receipts.isEmpty) return const SizedBox.shrink();
        final receipt = controller.receipts.first;
        final isSettlementOnly =
            (double.tryParse('${receipt['amount_paid']}') ?? 0) <= 0;
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(13.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.customGreen1.withValues(alpha: .16),
              AppColors.operationalPurple.withValues(alpha: .09),
            ]),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.customGreen1.withValues(alpha: .45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.customGreen1.withValues(alpha: .09),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: const BoxDecoration(
                color: AppColors.customGreen1,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        isSettlementOnly
                            ? 'تسوية راتب بانتظار موافقتك'
                            : 'راتب بانتظار تأكيد الاستلام',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (controller.receipts.length > 1)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20.r)),
                        child: Text('${controller.receipts.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                      ),
                  ]),
                  SizedBox(height: 2.h),
                  Text(isSettlementOnly
                      ? 'تمت التسوية مقابل السلف • شهر ${_month(receipt)}'
                      : '${EmployeeSalaryReceiptController.money(receipt['amount_paid'])} شيكل • شهر ${_month(receipt)}'),
                  SizedBox(height: 7.h),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 38.h,
                        child: FilledButton.icon(
                          onPressed: () => _showReceipt(context, receipt),
                          icon: const Icon(Icons.draw_rounded, size: 19),
                          label: const Text('مراجعة وتوقيع'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.customGreen1),
                        ),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    IconButton.outlined(
                      tooltip: 'كل سندات رواتبي',
                      onPressed: () =>
                          Get.toNamed(AppRoutes.EMPLOYEESALARYRECEIPTSSCREEN),
                      icon: const Icon(Icons.history_rounded),
                    ),
                  ]),
                ])),
          ]),
        );
      });

  String _month(Map<String, dynamic> row) {
    final period = row['salary_period'];
    final raw = period is Map ? '${period['salary_month'] ?? ''}' : '';
    return raw.length >= 7 ? raw.substring(0, 7) : raw;
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> row) {
    final period = row['salary_period'];
    final batch = row['batch'];
    final isSettlementOnly =
        (double.tryParse('${row['amount_paid']}') ?? 0) <= 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                        color:
                            AppColors.operationalPurple.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(13.r)),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.operationalPurple),
                  ),
                  SizedBox(width: 9.w),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('إقرار استلام راتب',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('راجع التفاصيل قبل التوقيع'),
                      ])),
                ]),
                SizedBox(height: 14.h),
                _ReceiptAmounts(
                    period: period is Map ? period : const {},
                    amount: row['amount_paid']),
                SizedBox(height: 10.h),
                _InfoLine(
                    icon: Icons.calendar_month_rounded,
                    label: 'شهر الراتب',
                    value: _month(row)),
                _InfoLine(
                    icon: Icons.event_available_rounded,
                    label: 'تاريخ الصرف',
                    value:
                        batch is Map ? '${batch['payment_date'] ?? ''}' : ''),
                _InfoLine(
                    icon: Icons.fingerprint_rounded,
                    label: 'رقم الدفعة',
                    value: '#${row['id']}'),
                SizedBox(height: 12.h),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _signatureDialog(context, row);
                  },
                  icon: const Icon(Icons.draw_rounded),
                  label: Text(isSettlementOnly
                      ? 'أوافق على التسوية — التوقيع الآن'
                      : 'تم الاستلام — التوقيع الآن'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.customGreen1,
                      minimumSize: Size.fromHeight(49.h)),
                ),
                SizedBox(height: 7.h),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _disputeDialog(context, row);
                  },
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(isSettlementOnly
                      ? 'لا أوافق على التسوية'
                      : 'المبلغ غير مستلم أو توجد مشكلة'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: Size.fromHeight(46.h)),
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> _signatureDialog(
      BuildContext context, Map<String, dynamic> row) async {
    final signatureKey = GlobalKey();
    final strokes = <List<Offset>>[].obs;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('توقيع استلام الراتب'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'وقّع بإصبعك داخل المربع. توقيعك يعني أنك استلمت المبلغ الموضح.'),
            SizedBox(height: 10.h),
            RepaintBoundary(
              key: signatureKey,
              child: Container(
                height: 190.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: AppColors.operationalPurple, width: 1.5),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => strokes.add([details.localPosition]),
                  onPanUpdate: (details) {
                    if (strokes.isEmpty) return;
                    strokes.last.add(details.localPosition);
                    strokes.refresh();
                  },
                  child: Obx(() => CustomPaint(
                        painter: _SignaturePainter(
                            strokes.map((e) => List<Offset>.from(e)).toList()),
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
                    label: const Text('مسح التوقيع'),
                  ),
                )),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('إلغاء')),
          Obx(() => FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (strokes.isEmpty ||
                            strokes.every((line) => line.length < 2)) {
                          Get.snackbar(
                              'التوقيع مطلوب', 'وقّع داخل المربع أولاً');
                          return;
                        }
                        final boundary = signatureKey.currentContext
                            ?.findRenderObject() as RenderRepaintBoundary?;
                        if (boundary == null) return;
                        final image = await boundary.toImage(pixelRatio: 2.5);
                        final data = await image.toByteData(
                            format: ui.ImageByteFormat.png);
                        if (data == null) return;
                        final success = await controller.acknowledge(
                          int.parse('${row['id']}'),
                          data.buffer.asUint8List(),
                        );
                        if (success && context.mounted) Navigator.pop(context);
                      },
                child: controller.isSubmitting.value
                    ? SizedBox.square(
                        dimension: 18.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ التوقيع والتأكيد'),
              )),
        ],
      ),
    );
  }

  Future<void> _disputeDialog(
      BuildContext context, Map<String, dynamic> row) async {
    final reason = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اعتراض على دفعة الراتب'),
        content: TextField(
          controller: reason,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
              labelText: 'اشرح المشكلة', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final success = await controller.dispute(
                  int.parse('${row['id']}'), reason.text);
              if (success && context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إرسال للإدارة'),
          ),
        ],
      ),
    );
    reason.dispose();
  }
}

class _ReceiptAmounts extends StatelessWidget {
  const _ReceiptAmounts({required this.period, required this.amount});
  final Map period;
  final dynamic amount;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.operationalNavy, AppColors.operationalPurple]),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(children: [
          Expanded(
              child: _WhiteValue(
                  label: 'الاستحقاق', value: period['gross_entitlement'])),
          Expanded(
              child: _WhiteValue(
                  label: 'السلف', value: period['advances_applied'])),
          Expanded(
              child: _WhiteValue(
                  label: 'المبلغ المستلم', value: amount, highlight: true)),
        ]),
      );
}

class _WhiteValue extends StatelessWidget {
  const _WhiteValue(
      {required this.label, required this.value, this.highlight = false});
  final String label;
  final dynamic value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .7), fontSize: 9.sp)),
        FittedBox(
            child: Text(EmployeeSalaryReceiptController.money(value),
                style: TextStyle(
                    color: highlight ? const Color(0xFFFFD166) : Colors.white,
                    fontWeight: FontWeight.w900))),
        Text('شيكل',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .6), fontSize: 8.sp)),
      ]);
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(children: [
          Icon(icon, color: AppColors.operationalPurple, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);
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
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
