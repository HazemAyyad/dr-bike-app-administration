import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class EditTransactionSheet extends StatefulWidget {
  final LedgerTransaction transaction;

  const EditTransactionSheet({Key? key, required this.transaction})
      : super(key: key);

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late String type;
  late TextEditingController amountController;
  late TextEditingController noteController;
  late DateTime selectedDate;
  bool isSaving = false;
  bool isLoadingBoxes = true;
  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedBox = Rxn<ShownBoxesModel>();

  bool get _requiresBox => widget.transaction.isManual;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    type = tx.type;
    amountController =
        TextEditingController(text: tx.amount.toStringAsFixed(2));
    noteController = TextEditingController(text: tx.note ?? '');
    selectedDate = DateTime.tryParse(tx.transactionDate ?? '') ?? DateTime.now();
    _loadBoxes(tx.boxId);
  }

  Future<void> _loadBoxes(int? currentBoxId) async {
    AppDependencyRegistry.ensureDebtsModule();
    final usecase = GetShownBoxUsecase(
      boxesRepository: Get.find<BoxesImplement>(),
    );
    final boxes = await usecase.call(screen: 0);
    shownBoxesList.assignAll(
      boxes.where((b) => b.currency == 'شيكل').toList(),
    );
    if (currentBoxId != null) {
      selectedBox.value = shownBoxesList.firstWhereOrNull(
        (b) => b.boxId == currentBoxId,
      );
    }
    isLoadingBoxes = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('error'.tr, 'ledgerAmountRequired'.tr);
      return;
    }

    setState(() => isSaving = true);
    final controller = Get.find<DebtLedgerController>();
    final ok = await controller.updateTransaction(
      id: widget.transaction.id,
      type: type,
      amount: amount.toStringAsFixed(2),
      transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      boxId: selectedBox.value?.boxId.toString(),
    );

    setState(() => isSaving = false);

    if (ok) {
      Get.back(result: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar('success'.tr, 'ledgerUpdated'.tr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'ledgerEditTransaction'.tr,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('took'.tr),
                    selected: type == 'taken',
                    selectedColor:
                        LedgerColors.takenGreen.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => type = 'taken'),
                  ),
                  SizedBox(width: 8.w),
                  ChoiceChip(
                    label: Text('gave'.tr),
                    selected: type == 'given',
                    selectedColor: LedgerColors.givenRed.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => type = 'given'),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'ledgerAmount'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              if (_requiresBox) ...[
                if (isLoadingBoxes)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else
                  Obx(
                    () => CustomDropdownFieldWithSearch(
                      tital: 'ledgerBoxOptional'.tr,
                      hint: 'boxName',
                      validator: (_) => null,
                      items: shownBoxesList,
                      onChanged: (value) => selectedBox.value = value,
                      itemAsString: (item) =>
                          '${item.boxName} - (${item.totalBalance} ${item.currency})',
                      compareFn: (a, b) => a.boxId == b.boxId,
                      value: selectedBox.value,
                    ),
                  ),
                SizedBox(height: 12.h),
              ] else
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    'ledgerInstantSaleNoBoxEdit'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('ledgerStartDate'.tr),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ar'),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              TextField(
                controller: noteController,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'ledgerAddNote'.tr,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LedgerColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: isSaving ? null : _save,
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          'save'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
