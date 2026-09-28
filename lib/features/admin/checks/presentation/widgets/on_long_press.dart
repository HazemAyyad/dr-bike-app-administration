import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/app_failure_notice.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../../payment_method/presentation/views/payment_screen.dart';
import '../../../widgets/unified_partner_selector.dart';
import '../../data/models/check_model.dart';
import '../controllers/checks_controller.dart';
import 'view_checks_widget.dart';

class OnLongPress extends GetView<ChecksController> {
  const OnLongPress({Key? key, required this.check}) : super(key: key);

  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    final actedTabIndex = controller.isInComing ? 1 : 2;
    final archiveTabIndex = controller.isInComing ? 2 : 3;
    final isOpenTab = controller.currentTab.value == 0 ||
        (!controller.isInComing && controller.currentTab.value == 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ViewChecksWidget(
            type: controller.isInComing,
            check: check,
            shadowed: false,
            currentTab: controller.currentTab.value,
          ),
        ),
        Dialog(
          backgroundColor: ThemeService.isDark.value
              ? AppColors.darkColor
              : AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Container(
                // padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                ),
                child: Column(
                  children: (isOpenTab
                          ? controller.isInComing
                              ? controller.incomingChecksDidNotActOnIt
                              : check.status == 'restructured_parent'
                                  ? controller.scheduledParentActions
                                  : check.installments.isNotEmpty
                                      ? controller.internalScheduleActions
                                      : check.parentOutgoingCheckId != null
                                          ? controller
                                              .scheduledOutgoingCheckActions
                                          : controller
                                              .outgoingChecksDidNotActOnIt
                          : controller.currentTab.value == actedTabIndex
                              ? controller.isInComing
                                  ? controller.incomingChecksActedOnIt
                                  : controller.outgoingChecksActedOnIt
                              : controller.archive)
                      .map<Widget>(
                        (option) => RadioListTile<String>(
                          title: Text(
                            option.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          value: option,
                          // ignore: deprecated_member_use
                          groupValue: null,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            Get.back();
                            if (value == 'voidTheCheck') {
                              Get.dialog(
                                IfCancelCheck(
                                  check: check,
                                  isReturn: false,
                                  toPerson: false,
                                ),
                              );
                            }
                            if (value == 'endorseTheCheck') {
                              Get.dialog(
                                CashTheCheck(
                                  label: 'beneficiary'.tr,
                                  hint: 'customerNameExample'.tr,
                                  check: check,
                                ),
                              );
                            }
                            if (value == 'deleteCheck') {
                              Get.dialog(
                                DeleteCheck(
                                  checkId: check.id.toString(),
                                  cascade: check.settledAmount > 0 ||
                                      check.installments.isNotEmpty,
                                ),
                              );
                            }
                            if (value == 'cashTheCheck') {
                              Get.dialog(
                                controller.currentTab.value != archiveTabIndex
                                    ? CashToBox(
                                        label: 'boxName',
                                        hint: 'boxNameExample',
                                        check: check,
                                      )
                                    : IfCancelCheck(
                                        check: check,
                                        isReturn: false,
                                        toPerson: true,
                                      ),
                              );
                            }
                            if (value == 'partialSettleCheck') {
                              Get.dialog(PartialSettlementDialog(check: check));
                            }
                            if (value == 'editCheckSchedule') {
                              Get.dialog(ScheduleEditDialog(check: check));
                            }
                            if (value == 'returnedCheck') {
                              Get.dialog(
                                IfCancelCheck(
                                  check: check,
                                  isReturn: true,
                                  toPerson: true,
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PartialSettlementDialog extends StatefulWidget {
  const PartialSettlementDialog({Key? key, required this.check})
      : super(key: key);
  final CheckModel check;

  @override
  State<PartialSettlementDialog> createState() =>
      _PartialSettlementDialogState();
}

class ScheduleEditDialog extends StatefulWidget {
  const ScheduleEditDialog({Key? key, required this.check}) : super(key: key);
  final CheckModel check;

  @override
  State<ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<ScheduleEditDialog> {
  final rows = <_InstallmentDraft>[];
  final picker = ImagePicker();
  ChecksController get controller => Get.find<ChecksController>();

  @override
  void initState() {
    super.initState();
    for (final item in widget.check.installments) {
      final row = _InstallmentDraft()
        ..amount.text = item.amount.toStringAsFixed(2)
        ..dueDate = item.dueDate
        ..replacement = item.instrumentType == 'replacement_check'
        ..checkNumber.text = item.checkId ?? ''
        ..bank.text = item.bankName ?? '';
      rows.add(row);
    }
  }

  @override
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(_InstallmentDraft row) async {
    final value = await showDatePicker(
      context: context,
      initialDate: row.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => row.dueDate = value);
  }

  Future<void> _submit() async {
    final data = <Map<String, dynamic>>[];
    for (final row in rows) {
      final amount = double.tryParse(row.amount.text.trim()) ?? 0;
      if (amount <= 0 ||
          (row.replacement &&
              (row.checkNumber.text.trim().isEmpty ||
                  row.bank.text.trim().isEmpty))) {
        AppFailureNotice.show(
            title: 'error'.tr, message: 'أكمل بيانات ومبالغ الجدولة');
        return;
      }
      data.add({
        'amount': amount,
        'due_date': _date(row.dueDate),
        'instrument_type': row.replacement ? 'replacement_check' : 'same_check',
        if (row.replacement) 'check_id': row.checkNumber.text.trim(),
        if (row.replacement) 'bank_name': row.bank.text.trim(),
        if (row.frontImage != null) 'front_image_file': row.frontImage,
        if (row.backImage != null) 'back_image_file': row.backImage,
      });
    }
    await controller.updateOutgoingCheckSchedule(
        check: widget.check, installments: data);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .82, maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تعديل الجدولة والشيكات التابعة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => rows.add(_InstallmentDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دفعة'),
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final row = entry.value;
                return Card(
                  color: const Color(0xFFF1F5F9),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text('الدفعة ${entry.key + 1}',
                                style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w800)),
                          ),
                          if (rows.length > 1)
                            IconButton(
                              onPressed: () => setState(() {
                                rows.removeAt(entry.key).dispose();
                              }),
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFF991B1B)),
                            ),
                        ]),
                        TextField(
                            controller: row.amount,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'المبلغ')),
                        ListTile(
                          dense: true,
                          title: const Text('تاريخ الاستحقاق'),
                          subtitle: Text(_date(row.dueDate)),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () => _pickDate(row),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('شيك بديل فعلي'),
                          value: row.replacement,
                          onChanged: (value) =>
                              setState(() => row.replacement = value),
                        ),
                        if (row.replacement) ...[
                          TextField(
                              controller: row.checkNumber,
                              decoration: const InputDecoration(
                                  labelText: 'رقم الشيك')),
                          TextField(
                              controller: row.bank,
                              decoration:
                                  const InputDecoration(labelText: 'البنك')),
                          Row(
                            children: [
                              Expanded(
                                  child: TextButton.icon(
                                      onPressed: () async {
                                        row.frontImage = await picker.pickImage(
                                            source: ImageSource.gallery);
                                        if (mounted) setState(() {});
                                      },
                                      icon: const Icon(Icons.image_outlined),
                                      label: Text(row.frontImage == null
                                          ? 'الصورة الأمامية'
                                          : 'تم اختيار الأمامية'))),
                              Expanded(
                                  child: TextButton.icon(
                                      onPressed: () async {
                                        row.backImage = await picker.pickImage(
                                            source: ImageSource.gallery);
                                        if (mounted) setState(() {});
                                      },
                                      icon: const Icon(Icons.image_outlined),
                                      label: Text(row.backImage == null
                                          ? 'الصورة الخلفية'
                                          : 'تم اختيار الخلفية'))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              Obx(() => FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF111827),
                    ),
                    onPressed: controller.isLoading.value ? null : _submit,
                    child: const Text('حفظ التعديلات'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartialSettlementDialogState extends State<PartialSettlementDialog> {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final List<_InstallmentDraft> installments = [];
  String? boxId;
  DateTime paidAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    checks.getOutgoingPaymentBoxes();
    for (final existing
        in widget.check.installments.where((row) => row.status == 'pending')) {
      final row = _InstallmentDraft();
      row.amount.text = existing.amount.toStringAsFixed(2);
      row.dueDate = existing.dueDate;
      row.replacement = existing.instrumentType == 'replacement_check';
      row.checkNumber.text = existing.checkId ?? '';
      row.bank.text = existing.bankName ?? '';
      installments.add(row);
    }
  }

  ChecksController get checks => Get.find<ChecksController>();

  double get payment => double.tryParse(amountController.text.trim()) ?? 0;
  double get remaining =>
      (widget.check.remainingAmount - payment).clamp(0, double.infinity);

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    for (final row in installments) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(BuildContext context, ValueChanged<DateTime> onPicked,
      DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => onPicked(date));
  }

  String dateText(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  void addInstallment() {
    setState(() {
      final row = _InstallmentDraft();
      final unallocated = remaining -
          installments.fold<double>(
              0, (sum, item) => sum + (double.tryParse(item.amount.text) ?? 0));
      if (unallocated > 0) row.amount.text = unallocated.toStringAsFixed(2);
      installments.add(row);
    });
  }

  Future<void> submit() async {
    if (payment <= 0 || payment > widget.check.remainingAmount) {
      AppFailureNotice.show(
          title: 'error'.tr, message: 'أدخل مبلغًا صحيحًا لا يتجاوز المتبقي');
      return;
    }
    final rows = <Map<String, dynamic>>[];
    for (final row in installments) {
      final amount = double.tryParse(row.amount.text.trim()) ?? 0;
      if (amount <= 0 ||
          (row.replacement &&
              (row.checkNumber.text.trim().isEmpty ||
                  row.bank.text.trim().isEmpty))) {
        AppFailureNotice.show(
            title: 'error'.tr, message: 'أكمل مبالغ وبيانات الشيكات البديلة');
        return;
      }
      rows.add({
        'amount': amount,
        'due_date': dateText(row.dueDate),
        'instrument_type': row.replacement ? 'replacement_check' : 'same_check',
        if (row.replacement) 'check_id': row.checkNumber.text.trim(),
        if (row.replacement) 'bank_name': row.bank.text.trim(),
      });
    }
    final scheduled =
        rows.fold<double>(0, (sum, row) => sum + (row['amount'] as double));
    if (rows.isNotEmpty && (scheduled - remaining).abs() > 0.001) {
      AppFailureNotice.show(
          title: 'error'.tr,
          message:
              'مجموع الدفعات ${scheduled.toStringAsFixed(2)} ويجب أن يساوي المتبقي ${remaining.toStringAsFixed(2)}');
      return;
    }
    await checks.partialSettleOutgoingCheck(
      check: widget.check,
      boxId: boxId,
      amount: payment,
      paidAt: paidAt,
      installments: rows,
      notes: notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF8FAFC);
    const fieldSurface = Color(0xFFF1F5F9);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF475569);
    const borderColor = Color(0xFFE2E8F0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .82, maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: fieldSurface,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelStyle: const TextStyle(color: mutedText),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 1.4),
                  ),
                ),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'دفع جزئي / إعادة جدولة',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'إغلاق',
                          onPressed: Get.back,
                          icon:
                              const Icon(Icons.close_rounded, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: fieldSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 5,
                        children: [
                          _SettlementSummaryText(
                              label: 'الأصلية',
                              value: widget.check.total.toString()),
                          _SettlementSummaryText(
                              label: 'المدفوع',
                              value: widget.check.settledAmount
                                  .toStringAsFixed(2)),
                          _SettlementSummaryText(
                              label: 'المتبقي',
                              value: widget.check.remainingAmount
                                  .toStringAsFixed(2)),
                          Text(widget.check.currency,
                              style: const TextStyle(
                                  color: mutedText,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      final boxes = checks.outgoingPaymentBoxesList
                          .where((b) => b.currency == widget.check.currency)
                          .toList();
                      return CustomDropdownFieldWithSearch(
                        tital: 'الصندوق (اختياري)',
                        hint: boxes.isEmpty
                            ? 'متابعة بدون صندوق'
                            : 'اختر صندوقًا أو اتركه فارغًا',
                        items: boxes,
                        onChanged: (value) => boxId = value?.boxId.toString(),
                        itemAsString: (item) =>
                            '${item.boxName} - (${item.totalBalance} ${item.currency})',
                        compareFn: (a, b) => a.boxId == b.boxId,
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            labelText: 'المبلغ المدفوع الآن',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 4),
                    ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        tileColor: fieldSurface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        title: const Text('تاريخ الدفع',
                            style: TextStyle(color: textColor)),
                        subtitle: Text(dateText(paidAt),
                            style: const TextStyle(color: mutedText)),
                        trailing: const Icon(Icons.calendar_month,
                            color: AppColors.primaryColor),
                        onTap: () =>
                            pickDate(context, (v) => paidAt = v, paidAt)),
                    Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F7),
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            'المتبقي بعد الدفع: ${remaining.toStringAsFixed(2)} ${widget.check.currency} — لن يتأثر حساب الشخص مرة أخرى.',
                            style: const TextStyle(
                                color: textColor, fontSize: 13))),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Expanded(
                          child: Text('جدولة المتبقي',
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800))),
                      TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryColor),
                          onPressed: remaining > 0 ? addInstallment : null,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة دفعة'))
                    ]),
                    ...installments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      return Card(
                          color: const Color(0xFFF1F5F9),
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(color: borderColor),
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: Text('الدفعة ${index + 1}')),
                                  IconButton(
                                      onPressed: () => setState(() {
                                            installments
                                                .removeAt(index)
                                                .dispose();
                                          }),
                                      icon: const Icon(Icons.delete_outline))
                                ]),
                                TextField(
                                    controller: row.amount,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'المبلغ')),
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('تاريخ الاستحقاق'),
                                    subtitle: Text(dateText(row.dueDate)),
                                    trailing: const Icon(Icons.calendar_month),
                                    onTap: () => pickDate(context,
                                        (v) => row.dueDate = v, row.dueDate)),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('شيك بديل فعلي'),
                                    value: row.replacement,
                                    onChanged: (v) =>
                                        setState(() => row.replacement = v)),
                                if (row.replacement) ...[
                                  TextField(
                                      controller: row.checkNumber,
                                      decoration: const InputDecoration(
                                          labelText: 'رقم الشيك الجديد')),
                                  TextField(
                                      controller: row.bank,
                                      decoration: const InputDecoration(
                                          labelText: 'البنك')),
                                ],
                              ])));
                    }),
                    TextField(
                        controller: notesController,
                        minLines: 1,
                        maxLines: 2,
                        decoration:
                            const InputDecoration(labelText: 'ملاحظات')),
                    const SizedBox(height: 12),
                    Obx(() => FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: textColor,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: AppColors.primaryColor),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: checks.isLoading.value ? null : submit,
                        child: checks.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('تأكيد التسديد',
                                style:
                                    TextStyle(fontWeight: FontWeight.w800)))),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettlementSummaryText extends StatelessWidget {
  const _SettlementSummaryText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
                color: Color(0xFF111827), fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InstallmentDraft {
  final amount = TextEditingController();
  final checkNumber = TextEditingController();
  final bank = TextEditingController();
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));
  bool replacement = false;
  XFile? frontImage;
  XFile? backImage;
  void dispose() {
    amount.dispose();
    checkNumber.dispose();
    bank.dispose();
  }
}

class IfCancelCheck extends GetView<ChecksController> {
  const IfCancelCheck({
    Key? key,
    required this.check,
    required this.isReturn,
    required this.toPerson,
  }) : super(key: key);

  final CheckModel check;
  final bool isReturn;
  final bool toPerson;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(8.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 5.h),
            Text(
              'areYouSure'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    isLoading: controller.isLoading,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'yes'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      isReturn
                          ? controller.returnCheck(
                              checkId: check.id.toString(),
                              isCancel: false,
                            )
                          : toPerson
                              ? !controller.isInComing
                                  ? Get.bottomSheet(
                                      PaymentScreen(
                                        type: 'payment',
                                        isSeller: check.customer != null ||
                                            check.toCustomer != null,
                                        id: check.customer != null
                                            ? check.customer!.id.toString()
                                            : check.toCustomer != null
                                                ? check.toCustomer!.id
                                                    .toString()
                                                : check.seller != null
                                                    ? check.seller!.id
                                                        .toString()
                                                    : check.toSeller!.id
                                                        .toString(),
                                      ),
                                      backgroundColor: Colors.white,
                                      isScrollControlled: true,
                                    ).then((value) {
                                      if (PaymentController.isSuccessResult(
                                          value)) {
                                        // ignore: use_build_context_synchronously
                                        controller.cashedToPersonOrCashed(
                                          checkId: check.id.toString(),
                                        );
                                      }
                                    })
                                  : controller.cashedToPersonOrCashed(
                                      checkId: check.id.toString(),
                                    )
                              : controller.returnCheck(
                                  checkId: check.id.toString(),
                                  isCancel: true,
                                );
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    color: Colors.red,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'cancel'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      Get.back();
                    },
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

class CashTheCheck extends GetView<ChecksController> {
  const CashTheCheck({
    Key? key,
    required this.label,
    required this.hint,
    required this.check,
  }) : super(key: key);

  final String label;
  final String hint;
  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    final selectedPartner = Rxn<SellerModel>();
    final selectedIsSeller = true.obs;
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Obx(() => UnifiedPartnerSelector<SellerModel>(
                  customers: controller.allCustomersList,
                  sellers: controller.allSellersList,
                  selected: selectedPartner.value,
                  selectedIsSeller: selectedIsSeller.value,
                  idOf: (partner) => partner.id,
                  nameOf: (partner) => partner.name,
                  phoneOf: (partner) => partner.phone,
                  onSelected: (partner, isSeller) {
                    selectedIsSeller.value = isSeller;
                    selectedPartner.value = partner;
                  },
                  onCleared: () => selectedPartner.value = null,
                  onAddRequested: (isSeller) async {
                    await Get.toNamed(
                      AppRoutes.ADDNEWCUSTOMERSCREEN,
                      arguments: {
                        'sellerId': '',
                        'employeeId': '',
                        'employeeType': isSeller ? 'seller' : 'customer',
                        'popOnceOnSuccess': true,
                      },
                    );
                    controller.getAllCustomersAndSellers();
                  },
                  title: label,
                  hintText: hint,
                  requiredSelection: true,
                  compact: true,
                )),
          ),
          AppButton(
            isSafeArea: false,
            isLoading: controller.isLoading,
            height: 48.h,
            width: double.infinity,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.r),
              bottomRight: Radius.circular(8.r),
            ),
            text: 'cashTheCheck',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
            onPressed: () {
              final partner = selectedPartner.value;
              if (partner == null) return;
              controller.cashedToPersonOrCashed(
                checkId: check.id.toString(),
                customerId:
                    selectedIsSeller.value ? null : partner.id.toString(),
                sellerId: selectedIsSeller.value ? partner.id.toString() : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class CashToBox extends GetView<ChecksController> {
  const CashToBox({
    Key? key,
    required this.label,
    required this.hint,
    required this.check,
  }) : super(key: key);

  final String label;
  final String hint;
  final CheckModel check;

  @override
  Widget build(BuildContext context) {
    final RxnString selectedValue = RxnString();
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: CustomDropdownFieldWithSearch(
                    tital: label,
                    hint: hint,
                    titalTextStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                    items: controller.shownBoxesList
                        .where((element) => element.currency == check.currency)
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedValue.value = value.boxId.toString();
                      }
                    },
                    itemAsString: (item) =>
                        '${item.boxName} - (${item.totalBalance} ${item.currency})',
                    compareFn: (a, b) => a.boxId == b.boxId,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.CREATEBOXESSCREEN),
                  icon: Icon(
                    Icons.add_circle_sharp,
                    color: AppColors.primaryColor,
                    size: 35.sp,
                  ),
                )
              ],
            ),
          ),
          AppButton(
            isSafeArea: false,
            isLoading: controller.isLoading,
            height: 48.h,
            width: double.infinity,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.r),
              bottomRight: Radius.circular(8.r),
            ),
            text: 'cashTheCheck',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
            onPressed: () {
              if (selectedValue.value != null) {
                controller.chashToBox(
                  checkId: check.id.toString(),
                  boxId: selectedValue.value!,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class DeleteCheck extends GetView<ChecksController> {
  const DeleteCheck({Key? key, required this.checkId, this.cascade = false})
      : super(key: key);

  final String checkId;
  final bool cascade;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 5.h),
            Text(
              cascade
                  ? 'سيتم حذف الشيك الأساسي وكل الدفعات والشيكات التابعة والقيود المرتبطة، وإعادة أي مبلغ خُصم من صندوق. هل أنت متأكد؟'
                  : 'areYouSure'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    isLoading: controller.isLoading,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'yes'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      // print("checkId23123123 $checkId");
                      controller.deleteCheck(checkId: checkId);
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: AppButton(
                    isSafeArea: false,
                    color: Colors.red,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.r),
                    ),
                    text: 'cancel'.tr,
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                    onPressed: () {
                      Get.back();
                    },
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
