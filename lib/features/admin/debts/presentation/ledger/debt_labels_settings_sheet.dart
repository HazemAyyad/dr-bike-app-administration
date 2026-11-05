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
  late String scope;
  final Map<String, TextEditingController> appearanceControllers = {};
  static const appearanceFields = {
    'receivable_label': 'مسمى الرصيد لنا',
    'payable_label': 'مسمى الرصيد علينا',
    'receipt_color': 'لون القبض',
    'payment_color': 'لون الدفع',
    'invoice_color': 'لون الفواتير',
    'receivable_color': 'لون الرصيد لنا',
    'payable_color': 'لون الرصيد علينا',
    'settled_color': 'لون الحساب المسدد',
  };
  static const appearanceDefaults = {
    'receivable_label': 'لك',
    'payable_label': 'عليك',
    'receipt_color': '1B8A4A',
    'payment_color': 'C62828',
    'invoice_color': '4A7FD4',
    'receivable_color': '1B8A4A',
    'payable_color': 'C62828',
    'settled_color': '757575',
  };
  final Map<String, List<String>> drafts = {};

  static const scopes = {
    'general': 'عام / باقي الحسابات',
    'customers': 'العملاء',
    'sellers': 'الموردون',
    'private': 'خاص',
  };

  @override
  void initState() {
    super.initState();
    final ledger = Get.find<DebtLedgerController>();
    for (final key in appearanceFields.keys) {
      appearanceControllers[key] = TextEditingController(
        text:
            ledger.debtLabels.value.appearance[key] ?? appearanceDefaults[key],
      );
    }
    scope = ledger.tabLabelScope;
    final labels = ledger.debtLabels.value.forScope(scope);
    takenController = TextEditingController(text: labels.taken);
    givenController = TextEditingController(text: labels.given);
  }

  @override
  void dispose() {
    for (final controller in appearanceControllers.values) {
      controller.dispose();
    }
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
                  'اختر نوع الحساب وغيّر مسمياته، ثم احفظ لهذا النوع. النوع غير المخصص يستخدم المسميات العامة. لا تتغير مبالغ الحركات أو أرصدتها.',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                ),
                SizedBox(height: 18.h),
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: scope,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'تخصيص المسميات لـ',
                        border: OutlineInputBorder(),
                      ),
                      items: scopes.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: ledger.isSavingDebtLabels.value
                          ? null
                          : (value) {
                              if (value == null || value == scope) return;
                              drafts[scope] = [
                                takenController.text,
                                givenController.text
                              ];
                              final labels =
                                  ledger.debtLabels.value.forScope(value);
                              setState(() {
                                scope = value;
                                takenController.text =
                                    drafts[value]?[0] ?? labels.taken;
                                givenController.text =
                                    drafts[value]?[1] ?? labels.given;
                              });
                            },
                    )),
                SizedBox(height: 18.h),
                if (scope != 'general')
                  Obx(() => TextButton.icon(
                        onPressed: ledger.isSavingDebtLabels.value
                            ? null
                            : () => _save(useGeneral: true),
                        icon: const Icon(Icons.link),
                        label: const Text('استخدام المسميات العامة'),
                      )),
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
                SizedBox(height: 12.h),
                const Text('المسميات والألوان لجميع حسابات الديون'),
                ...appearanceFields.entries.map((entry) {
                  final isColor = entry.key.endsWith('_color');
                  final controller = appearanceControllers[entry.key]!;
                  final value = int.tryParse(controller.text, radix: 16);
                  return Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: TextField(
                      controller: controller,
                      maxLength: isColor ? 6 : 30,
                      textDirection:
                          isColor ? TextDirection.ltr : TextDirection.rtl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: entry.value,
                        helperText:
                            isColor ? 'رمز HEX من 6 خانات مثل 1B8A4A' : null,
                        suffixIcon: isColor
                            ? Icon(Icons.circle,
                                color: value == null
                                    ? Colors.grey
                                    : Color(0xFF000000 | value))
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 8.h),
                Obx(() => Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12.w,
                      runSpacing: 8.h,
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
                              : 'حفظ لهذا النوع'),
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

  Future<void> _save({bool useGeneral = false}) async {
    FocusScope.of(context).unfocus();
    final ledger = Get.find<DebtLedgerController>();
    for (final entry in appearanceControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty ||
          (entry.key.endsWith('_color') &&
              (value.length != 6 || int.tryParse(value, radix: 16) == null))) {
        await Get.dialog<void>(AlertDialog(
          title: const Text('تحقق من الإعدادات'),
          content: Text(appearanceFields[entry.key]!),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('حسناً'))
          ],
        ));
        return;
      }
    }
    final saved = await ledger.saveDebtLabels(
      takenController.text,
      givenController.text,
      scope: scope,
      useGeneral: useGeneral,
      appearance: appearanceControllers
          .map((key, controller) => MapEntry(key, controller.text.trim())),
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
