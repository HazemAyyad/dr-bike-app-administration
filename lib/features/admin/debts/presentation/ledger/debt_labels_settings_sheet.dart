import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class DebtLabelsSettingsSheet extends StatefulWidget {
  const DebtLabelsSettingsSheet({Key? key}) : super(key: key);

  @override
  State<DebtLabelsSettingsSheet> createState() =>
      _DebtLabelsSettingsSheetState();
}

class _DebtLabelsSettingsSheetState extends State<DebtLabelsSettingsSheet> {
  late final TextEditingController takenController;
  late final TextEditingController givenController;
  bool saving = false;

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20.w, 16.h, 20.w, MediaQuery.viewInsetsOf(context).bottom + 22.h),
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
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
              Row(
                children: [
                  TextButton.icon(
                    onPressed: saving
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
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: LedgerColors.primaryBlue,
                    ),
                    icon: saving
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final saved = await Get.find<DebtLedgerController>().saveDebtLabels(
      takenController.text,
      givenController.text,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) Get.back();
  }
}
