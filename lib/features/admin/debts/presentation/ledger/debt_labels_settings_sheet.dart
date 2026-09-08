import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import '../../../../../core/helpers/app_success_notice.dart';

class DebtLabelsSettingsSheet extends StatefulWidget {
  const DebtLabelsSettingsSheet({Key? key}) : super(key: key);

  @override
  State<DebtLabelsSettingsSheet> createState() =>
      _DebtLabelsSettingsSheetState();
}

class _DebtLabelsSettingsSheetState extends State<DebtLabelsSettingsSheet> {
  late final TextEditingController takenController;
  late final TextEditingController givenController;

  @override
  void initState() {
    super.initState();
    final ledger = Get.find<DebtLedgerController>();
    takenController = TextEditingController(text: ledger.takenLabel.value);
    givenController = TextEditingController(text: ledger.givenLabel.value);
  }

  @override
  void dispose() {
    takenController.dispose();
    givenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Get.find<DebtLedgerController>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: LedgerColors.primaryBlue),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'مسميات حركات الديون',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'غيّر الكلمات التي تظهر في القسم والتقارير. يمكنك الرجوع للوضع الافتراضي في أي وقت.',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: takenController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'بدل كلمة أخذت',
                    prefixIcon: Icon(Icons.south_west_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: givenController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'بدل كلمة أعطيت',
                    prefixIcon: Icon(Icons.north_east_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.h),
                Obx(() => Row(
                      children: [
                        TextButton.icon(
                          onPressed: ledger.isSavingDebtLabels.value
                              ? null
                              : () => setState(() {
                                    takenController.text = 'أخذت';
                                    givenController.text = 'أعطيت';
                                  }),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('الافتراضي'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed:
                              ledger.isSavingDebtLabels.value ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: LedgerColors.primaryBlue,
                          ),
                          icon: ledger.isSavingDebtLabels.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(ledger.isSavingDebtLabels.value
                              ? 'جاري الحفظ...'
                              : 'حفظ'),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final ledger = Get.find<DebtLedgerController>();
    final saved = await ledger.saveDebtLabels(
      takenController.text,
      givenController.text,
    );
    if (!mounted) return;
    if (saved) {
      Get.back();
      AppSuccessNotice.show(
        title: 'تم الحفظ',
        message: 'تم تحديث مسميات حركات الديون بنجاح',
      );
    } else {
      await Get.dialog<void>(
        AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 42),
          title: const Text('تعذر حفظ المسميات'),
          content: Text(
            ledger.debtLabelsSaveError.value.isEmpty
                ? 'حدث خطأ أثناء الحفظ. حاول مرة أخرى.'
                : ledger.debtLabelsSaveError.value,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('حسناً'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }
}
