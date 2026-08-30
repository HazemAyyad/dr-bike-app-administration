import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../common_feature/presentation/user_profile/controllers/employee_signatures_controller.dart';
import '../../../../common_feature/presentation/user_profile/widgets/signature_capture_flow.dart';
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
    EmployeeDashbordBinding.ensureEmployeeSignaturesController();
    final signatures = Get.find<EmployeeSignaturesController>();
    await signatures.load();
    if (!context.mounted) return;
    final selectedId = RxnInt(signatures.defaultSignature?.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .78,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.customGreen1.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: AppColors.customGreen1),
                ),
                SizedBox(width: 9.w),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختر توقيع الاستلام',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                      Text('يجب تأكيد استخدام التوقيع لكل سند بشكل مستقل'),
                    ],
                  ),
                ),
              ]),
              SizedBox(height: 12.h),
              if (signatures.signatures.isEmpty)
                Expanded(
                  child: _NoSavedSignature(
                    onCreate: () async {
                      Navigator.pop(sheetContext);
                      await _useNewSignature(context, row, signatures);
                    },
                  ),
                )
              else ...[
                Expanded(
                  child: Obx(() => ListView.separated(
                        itemCount: signatures.signatures.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, index) {
                          final signature = signatures.signatures[index];
                          return Obx(() => _SalarySignatureOption(
                                signature: signature,
                                selected: selectedId.value == signature.id,
                                onTap: () => selectedId.value = signature.id,
                              ));
                        },
                      )),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _useNewSignature(context, row, signatures);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إنشاء توقيع جديد لهذه العملية'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(46.h),
                  ),
                ),
                SizedBox(height: 8.h),
                Obx(() => FilledButton.icon(
                      onPressed: selectedId.value == null ||
                              controller.isSubmitting.value
                          ? null
                          : () async {
                              final accepted = await _confirmSignatureUse(
                                context,
                                signatures.signatures
                                    .firstWhere(
                                      (item) => item.id == selectedId.value,
                                    )
                                    .name,
                              );
                              if (!accepted) return;
                              final success =
                                  await controller.acknowledgeStored(
                                int.parse('${row['id']}'),
                                selectedId.value!,
                              );
                              if (success && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      icon: controller.isSubmitting.value
                          ? SizedBox.square(
                              dimension: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: const Text('استخدام التوقيع وتأكيد الاستلام'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.customGreen1,
                        minimumSize: Size.fromHeight(49.h),
                      ),
                    )),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _useNewSignature(
    BuildContext context,
    Map<String, dynamic> row,
    EmployeeSignaturesController signatures,
  ) async {
    final capture = await showEmployeeSignatureCapture(context);
    if (capture == null || !context.mounted) return;
    final name = TextEditingController(
        text: signatures.signatures.isEmpty
            ? 'التوقيع الرسمي'
            : 'توقيع ${signatures.signatures.length + 1}');
    final save = true.obs;
    final makeDefault = signatures.signatures.isEmpty.obs;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد التوقيع الجديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            height: 115.h,
            width: double.infinity,
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.operationalCardBorder),
            ),
            child: Image.memory(capture.processedBytes, fit: BoxFit.contain),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'اسم التوقيع',
              border: OutlineInputBorder(),
            ),
          ),
          Obx(() => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: save.value,
                onChanged: (value) => save.value = value ?? false,
                title: const Text('حفظ التوقيع في ملفي'),
              )),
          Obx(() => save.value
              ? CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: makeDefault.value,
                  onChanged: (value) => makeDefault.value = value ?? false,
                  title: const Text('تعيينه كتوقيع افتراضي'),
                )
              : const SizedBox.shrink()),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('توقيع وتأكيد الاستلام'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      final success = await controller.acknowledgeNew(
        int.parse('${row['id']}'),
        capture.originalBytes,
        source: capture.source,
        name: name.text.trim().isEmpty ? 'توقيع الراتب' : name.text.trim(),
        saveSignature: save.value,
        makeDefault: makeDefault.value,
      );
      if (success && save.value) await signatures.load();
    }
    name.dispose();
  }

  Future<bool> _confirmSignatureUse(
      BuildContext context, String signatureName) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.verified_rounded,
                color: AppColors.customGreen1, size: 42),
            title: const Text('تأكيد استلام الراتب'),
            content: Text(
              'سيتم استخدام «$signatureName» لتوثيق استلام هذا السند. هل تؤكد الاستلام؟',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('رجوع'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('أؤكد الاستلام'),
              ),
            ],
          ),
        ) ??
        false;
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

class _SalarySignatureOption extends StatelessWidget {
  const _SalarySignatureOption({
    required this.signature,
    required this.selected,
    required this.onTap,
  });
  final EmployeeSignatureModel signature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.customGreen1.withValues(alpha: .07)
                : AppColors.operationalSurface,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: selected
                  ? AppColors.customGreen1
                  : AppColors.operationalCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 92.w,
              height: 62.h,
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Image.network(
                signature.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(signature.name,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(
                    signature.isDefault ? 'التوقيع الافتراضي' : 'توقيع محفوظ',
                    style: TextStyle(
                      color:
                          signature.isDefault ? AppColors.customGreen1 : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.customGreen1 : Colors.grey,
            ),
          ]),
        ),
      );
}

class _NoSavedSignature extends StatelessWidget {
  const _NoSavedSignature({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.draw_outlined,
              size: 54.sp, color: AppColors.operationalPurple),
          SizedBox(height: 9.h),
          const Text('لا يوجد توقيع محفوظ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const Text(
            'أنشئ توقيعًا يدويًا أو صوّره أو ارفعه من الجهاز.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 13.h),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء توقيع الآن'),
          ),
        ]),
      );
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
