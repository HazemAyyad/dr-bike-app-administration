import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class PeriodFilterSheet extends StatelessWidget {
  const PeriodFilterSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    final periods = <Map<String, String>>[
      {'key': 'all', 'label': 'ledgerPeriodAll'.tr},
      {'key': 'today', 'label': 'ledgerPeriodToday'.tr},
      {'key': 'yesterday', 'label': 'ledgerPeriodYesterday'.tr},
      {'key': 'current_week', 'label': 'ledgerPeriodCurrentWeek'.tr},
      {'key': 'last_week', 'label': 'ledgerPeriodLastWeek'.tr},
      {'key': 'current_month', 'label': 'ledgerPeriodCurrentMonth'.tr},
      {'key': 'last_month', 'label': 'ledgerPeriodLastMonth'.tr},
      {'key': 'custom', 'label': 'ledgerPeriodCustom'.tr},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ledgerSelectPeriod'.tr,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Column(
              children: periods
                  .map(
                    (p) => RadioListTile<String>(
                      value: p['key']!,
                      groupValue: controller.selectedPeriod.value,
                      title: Text(p['label']!),
                      onChanged: (v) {
                        if (v == 'custom') {
                          controller.selectedPeriod.value = v!;
                        } else {
                          controller.applyPeriod(v!);
                          Get.back();
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Obx(() {
            if (controller.selectedPeriod.value != 'custom') {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                ListTile(
                  title: Text('ledgerStartDate'.tr),
                  subtitle: Text(
                    controller.customStartDate.value != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(controller.customStartDate.value!)
                        : '—',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('ar'),
                    );
                    if (date != null) controller.customStartDate.value = date;
                  },
                ),
                ListTile(
                  title: Text('ledgerEndDate'.tr),
                  subtitle: Text(
                    controller.customEndDate.value != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(controller.customEndDate.value!)
                        : '—',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('ar'),
                    );
                    if (date != null) controller.customEndDate.value = date;
                  },
                ),
              ],
            );
          }),
          SizedBox(height: 8.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LedgerColors.primaryBlue,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () {
              if (controller.selectedPeriod.value == 'custom') {
                controller.setCustomPeriod(
                  controller.customStartDate.value,
                  controller.customEndDate.value,
                );
              }
              Get.back();
            },
            child: Text('ledgerApply'.tr),
          ),
        ],
      ),
    );
  }
}
