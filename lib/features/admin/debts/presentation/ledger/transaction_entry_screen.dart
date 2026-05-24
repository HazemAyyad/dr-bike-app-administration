import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_currency_chips.dart';

class TransactionEntryScreen extends StatelessWidget {
  final String personName;
  final String type;
  final bool isCustomer;
  final int personId;

  const TransactionEntryScreen({
    Key? key,
    required this.personName,
    required this.type,
    required this.isCustomer,
    required this.personId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ledger = Get.find<DebtLedgerController>();
    final tag = 'calc_$personId';
    if (Get.isRegistered<TransactionCalculatorController>(tag: tag)) {
      Get.delete<TransactionCalculatorController>(tag: tag);
    }
    final calc = Get.put(
      TransactionCalculatorController(
        repository: ledger.repository,
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        personName: personName,
        initialType: type,
        isCustomer: isCustomer,
        personId: personId,
      ),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: LedgerColors.background,
      appBar: AppBar(
        title: Text(personName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LedgerColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: calc.isSaving.value ? null : calc.saveTransaction,
                child: calc.isSaving.value
                    ? SizedBox(
                        height: 24.h,
                        width: 24.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'ledgerRegister'.tr,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  Obx(
                    () => Text(
                      calc.display.value,
                      style: TextStyle(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        color: calc.transactionType.value == 'taken'
                            ? LedgerColors.takenGreen
                            : LedgerColors.givenRed,
                      ),
                    ),
                  ),
                  Obx(
                    () => calc.expression.value.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            calc.expression.value,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => ChoiceChip(
                          label: Text('took'.tr),
                          selected: calc.transactionType.value == 'taken',
                          selectedColor:
                              LedgerColors.takenGreen.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              calc.transactionType.value = 'taken',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Obx(
                        () => ChoiceChip(
                          label: Text('gave'.tr),
                          selected: calc.transactionType.value == 'given',
                          selectedColor:
                              LedgerColors.givenRed.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              calc.transactionType.value = 'given',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => LedgerCurrencyChips(
                      selected: calc.selectedCurrency.value,
                      onSelected: calc.setCurrency,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => CustomDropdownFieldWithSearch(
                      tital: 'ledgerBoxOptional'.tr,
                      hint: 'boxName',
                      validator: (_) => null,
                      items: calc.shownBoxesList,
                      onChanged: (value) {
                        calc.selectedBox.value = value;
                        if (value != null) {
                          calc.setCurrency(value.currency);
                        }
                      },
                      itemAsString: (item) =>
                          '${item.boxName} - (${item.totalBalance} ${item.currency})',
                      compareFn: (a, b) => a.boxId == b.boxId,
                      value: calc.selectedBox.value,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Obx(
                    () => TextButton.icon(
                      onPressed: calc.isSaving.value
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    calc.selectedDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                locale: const Locale('ar'),
                              );
                              if (date != null) calc.selectedDate.value = date;
                            },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(
                          calc.selectedDate.value ?? DateTime.now(),
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: calc.noteController,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'ledgerAddNote'.tr,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: calc.isSaving.value
                              ? null
                              : calc.pickReceiptImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text('ledgerAddImage'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LedgerColors.primaryBlue,
                            side: const BorderSide(color: LedgerColors.primaryBlue),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    if (calc.receiptImages.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 72.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: calc.receiptImages.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final file = calc.receiptImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(
                                  file,
                                  width: 72.w,
                                  height: 72.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () =>
                                      calc.removeReceiptImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                  _CalcPad(calc: calc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcPad extends StatelessWidget {
  final TransactionCalculatorController calc;

  const _CalcPad({required this.calc});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['AC', '⌫'],
      ['7', '8', '9', '/'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '=', '+'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            children: row.map((key) {
              return Expanded(
                flex: row.length == 2 ? 2 : 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Material(
                    color: _keyColor(key),
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: calc.isSaving.value
                          ? null
                          : () => _onKey(calc, key),
                      child: SizedBox(
                        height: 44.h,
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Color _keyColor(String key) {
    if (key == 'AC' || key == '⌫') {
      return LedgerColors.primaryBlue.withValues(alpha: 0.12);
    }
    if (['+', '-', '×', '/', '='].contains(key)) {
      return LedgerColors.primaryBlue.withValues(alpha: 0.15);
    }
    return Colors.white;
  }

  Future<void> _onKey(TransactionCalculatorController calc, String key) async {
    switch (key) {
      case 'AC':
        calc.clearAll();
        break;
      case '⌫':
        calc.backspace();
        break;
      case '=':
        calc.calculateResult();
        break;
      case '+':
      case '-':
      case '×':
      case '/':
      case '%':
        calc.applyOperator(key);
        break;
      default:
        calc.appendDigit(key);
    }
  }
}
