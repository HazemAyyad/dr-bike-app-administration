import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class ShareSheet extends StatelessWidget {
  const ShareSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ledgerShareReport'.tr,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _ShareButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Get.back();
                      controller.shareReportVia('whatsapp');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ShareButton(
                    icon: Icons.sms,
                    label: 'SMS',
                    color: LedgerColors.primaryBlue,
                    onTap: () {
                      Get.back();
                      controller.shareReportVia('sms');
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

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 6.h),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp (with voucher image) or SMS (text only) for a single transaction.
class TransactionShareSheet extends StatelessWidget {
  final LedgerTransaction transaction;

  const TransactionShareSheet({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ledgerShareTransaction'.tr,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _ShareButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Get.back();
                      controller.shareSingleTransactionVia(
                        transaction,
                        'whatsapp',
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ShareButton(
                    icon: Icons.sms,
                    label: 'SMS',
                    color: LedgerColors.primaryBlue,
                    onTap: () {
                      Get.back();
                      controller.shareSingleTransactionVia(
                        transaction,
                        'sms',
                      );
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

class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.receipt_long, color: LedgerColors.primaryBlue),
            title: Text('ledgerShareTransactions'.tr),
            onTap: () {
              Get.back();
              Get.bottomSheet(
                const ShareSheet(),
                isScrollControlled: true,
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: LedgerColors.primaryBlue,
            ),
            title: Text('ledgerSharePerformanceReminder'.tr),
            onTap: () {
              Get.back();
              Get.find<DebtLedgerController>().openPerformanceReminderSheet();
            },
          ),
        ],
      ),
    );
  }
}
