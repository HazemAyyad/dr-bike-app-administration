import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_currency_chips.dart';

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
  late String selectedCurrency;
  final RxList<ShownBoxesModel> allBoxes = <ShownBoxesModel>[].obs;
  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedBox = Rxn<ShownBoxesModel>();
  final RxList<File> receiptImages = <File>[].obs;

  bool get _requiresBox => widget.transaction.isManual;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    type = tx.type;
    amountController =
        TextEditingController(text: tx.amount.toStringAsFixed(2));
    noteController = TextEditingController(text: tx.note ?? '');
    selectedDate =
        DateTime.tryParse(tx.transactionDate ?? '') ?? DateTime.now();
    selectedCurrency = tx.currency;
    _loadBoxes(tx.boxId);
  }

  void _applyBoxFilter() {
    shownBoxesList.assignAll(
      allBoxes.where((b) => b.currency == selectedCurrency).toList(),
    );
    final box = selectedBox.value;
    if (box != null && box.currency != selectedCurrency) {
      selectedBox.value = null;
    }
  }

  Future<void> _loadBoxes(int? currentBoxId) async {
    AppDependencyRegistry.ensureDebtsModule();
    final usecase = GetShownBoxUsecase(
      boxesRepository: Get.find<BoxesImplement>(),
    );
    final boxes = await usecase.call(screen: 0);
    allBoxes.assignAll(boxes);
    _applyBoxFilter();
    if (currentBoxId != null) {
      selectedBox.value = allBoxes.firstWhereOrNull(
        (b) => b.boxId == currentBoxId,
      );
      if (selectedBox.value != null) {
        selectedCurrency = selectedBox.value!.currency;
        _applyBoxFilter();
      }
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

  Future<void> _pickReceiptImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    receiptImages
      ..clear()
      ..addAll(picked.map((x) => File(x.path)));
  }

  void _removeReceiptImage(int index) {
    if (index >= 0 && index < receiptImages.length) {
      receiptImages.removeAt(index);
    }
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
      currency: selectedBox.value?.currency ?? selectedCurrency,
      transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      boxId: selectedBox.value?.boxId.toString(),
      receiptImages:
          receiptImages.isEmpty ? null : List<File>.from(receiptImages),
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
              LedgerCurrencyChips(
                selected: selectedCurrency,
                onSelected: (currency) {
                  setState(() {
                    selectedCurrency = currency;
                    _applyBoxFilter();
                  });
                },
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
              SizedBox(height: 12.h),
              _ReceiptImageEditor(
                existingImages: widget.transaction.receiptImages,
                newImages: receiptImages,
                onPick: _pickReceiptImages,
                onRemoveNew: _removeReceiptImage,
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

class _ReceiptImageEditor extends StatelessWidget {
  const _ReceiptImageEditor({
    required this.existingImages,
    required this.newImages,
    required this.onPick,
    required this.onRemoveNew,
  });

  final List<String> existingImages;
  final RxList<File> newImages;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveNew;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasNewImages = newImages.isNotEmpty;
      final imagesToShow =
          hasNewImages ? newImages.length : existingImages.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              hasNewImages || existingImages.isNotEmpty
                  ? 'ledgerReplaceImages'.tr
                  : 'ledgerAddImage'.tr,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: LedgerColors.primaryBlue,
              side: const BorderSide(color: LedgerColors.primaryBlue),
              padding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
          if (existingImages.isNotEmpty && !hasNewImages) ...[
            SizedBox(height: 6.h),
            Text(
              'ledgerImageReplaceHint'.tr,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
          if (imagesToShow > 0) ...[
            SizedBox(height: 8.h),
            SizedBox(
              height: 76.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagesToShow,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  return hasNewImages
                      ? _NewReceiptThumb(
                          file: newImages[index],
                          onRemove: () => onRemoveNew(index),
                        )
                      : _ExistingReceiptThumb(image: existingImages[index]);
                },
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _ExistingReceiptThumb extends StatelessWidget {
  const _ExistingReceiptThumb({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final url = ShowNetImage.getPhoto(image);
    return GestureDetector(
      onTap: () => FullScreenZoomImage.open(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 76.w,
          height: 76.h,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _NewReceiptThumb extends StatelessWidget {
  const _NewReceiptThumb({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            file,
            width: 76.w,
            height: 76.h,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
