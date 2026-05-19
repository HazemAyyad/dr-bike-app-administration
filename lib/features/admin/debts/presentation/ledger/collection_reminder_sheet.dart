import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class CollectionReminderSheet extends StatelessWidget {
  const CollectionReminderSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    Future<void> pickAndSave(DateTime date) async {
      Get.back();
      final ok = await controller.setCollectionReminder(date);
      if (ok) {
        Get.snackbar('success'.tr, 'ledgerReminderSet'.tr);
      }
    }

    Future<void> pickCustom() async {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        locale: const Locale('ar'),
      );
      if (date != null) {
        await pickAndSave(date);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'ledgerSetReminderDate'.tr,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: LedgerColors.primaryBlue,
                ),
              ),
            ),
            _ReminderTile(
              icon: Icons.calendar_today_outlined,
              title: 'ledgerNextWeek'.tr,
              onTap: () => pickAndSave(controller.nextWeekReminderDate),
            ),
            _ReminderTile(
              icon: Icons.calendar_month_outlined,
              title: 'ledgerNextMonth'.tr,
              onTap: () => pickAndSave(controller.nextMonthReminderDate),
            ),
            _ReminderTile(
              icon: Icons.date_range_outlined,
              title: 'ledgerCustomDate'.tr,
              onTap: pickCustom,
            ),
            _ReminderTile(
              icon: Icons.delete_outline,
              iconColor: LedgerColors.givenRed,
              title: 'ledgerCancelReminder'.tr,
              titleColor: LedgerColors.givenRed,
              onTap: () async {
                Get.back();
                final ok = await controller.clearCollectionReminder();
                if (ok) {
                  Get.snackbar('success'.tr, 'ledgerReminderCancelled'.tr);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? LedgerColors.primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
