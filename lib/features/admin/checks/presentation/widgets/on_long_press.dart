import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/app_failure_notice.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
                  children: (controller.currentTab.value == 0
                          ? controller.isInComing
                              ? controller.incomingChecksDidNotActOnIt
                              : controller.outgoingChecksDidNotActOnIt
                          : controller.currentTab.value == 1
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
                                DeleteCheck(checkId: check.id.toString()),
                              );
                            }
                            if (value == 'cashTheCheck') {
                              Get.dialog(
                                controller.currentTab.value != 2
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
    if (boxId == null ||
        payment <= 0 ||
        payment > widget.check.remainingAmount) {
      AppFailureNotice.show(
          title: 'error'.tr,
          message: 'اختر الصندوق وأدخل مبلغًا صحيحًا لا يتجاوز المتبقي');
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
      boxId: boxId!,
      amount: payment,
      paidAt: paidAt,
      installments: rows,
      notes: notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .88, maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('دفع جزئي / إعادة جدولة',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      'القيمة الأصلية: ${widget.check.total} ${widget.check.currency}'),
                  Text(
                      'المدفوع سابقًا: ${widget.check.settledAmount.toStringAsFixed(2)} ${widget.check.currency}'),
                  Text(
                      'المتبقي: ${widget.check.remainingAmount.toStringAsFixed(2)} ${widget.check.currency}'),
                  const SizedBox(height: 12),
                  Obx(() {
                    final boxes = checks.outgoingPaymentBoxesList
                        .where((b) => b.currency == widget.check.currency)
                        .toList();
                    return CustomDropdownFieldWithSearch(
                      tital: 'boxName',
                      hint: boxes.isEmpty
                          ? 'لا يوجد صندوق صرف متاح بنفس العملة'
                          : 'boxNameExample',
                      items: boxes,
                      onChanged: (value) => boxId = value?.boxId.toString(),
                      itemAsString: (item) =>
                          '${item.boxName} - (${item.totalBalance} ${item.currency})',
                      compareFn: (a, b) => a.boxId == b.boxId,
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'المبلغ المدفوع الآن',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاريخ الدفع'),
                      subtitle: Text(dateText(paidAt)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () =>
                          pickDate(context, (v) => paidAt = v, paidAt)),
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          'المتبقي بعد الدفع: ${remaining.toStringAsFixed(2)} ${widget.check.currency}\nلن يتأثر حساب الشخص مرة أخرى.')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: Text('جدولة المتبقي',
                            style: Theme.of(context).textTheme.titleMedium)),
                    TextButton.icon(
                        onPressed: remaining > 0 ? addInstallment : null,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة دفعة'))
                  ]),
                  ...installments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Card(
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
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ملاحظات')),
                  const SizedBox(height: 16),
                  Obx(() => FilledButton(
                      onPressed: checks.isLoading.value ? null : submit,
                      child: checks.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('تأكيد التسديد'))),
                ]),
          ),
        ),
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
  const DeleteCheck({Key? key, required this.checkId}) : super(key: key);

  final String checkId;

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
