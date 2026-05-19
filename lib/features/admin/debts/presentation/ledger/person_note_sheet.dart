import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_flash_message_screen.dart';

class PersonNoteSheet extends StatefulWidget {
  final LedgerPersonInfo person;

  const PersonNoteSheet({Key? key, required this.person}) : super(key: key);

  @override
  State<PersonNoteSheet> createState() => _PersonNoteSheetState();
}

class _PersonNoteSheetState extends State<PersonNoteSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.person.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok =
        await Get.find<DebtLedgerController>().savePersonNotes(_controller.text);
    setState(() => _isSaving = false);
    if (ok && mounted) {
      Get.back();
      await LedgerFlashMessageScreen.show('ledgerNoteSaved'.tr);
    }
  }

  Future<void> _clear() async {
    _controller.clear();
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.person.hasNotes;

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
                'ledgerPersonNoteTitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: LedgerColors.primaryBlue,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                hasNote ? 'ledgerPersonNoteEditHint'.tr : 'ledgerPersonNoteAddHint'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'ledgerPersonNotePlaceholder'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LedgerColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'save'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
              if (hasNote) ...[
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: _isSaving ? null : _clear,
                  child: Text(
                    'ledgerClearNote'.tr,
                    style: TextStyle(color: LedgerColors.givenRed),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
