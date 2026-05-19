import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';

class TransactionDetailScreen extends GetView<DebtLedgerController> {
  const TransactionDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tx = controller.selectedTransaction.value;
      if (tx == null) {
        return Scaffold(
          appBar: AppBar(title: Text('ledgerTransactions'.tr)),
          body: Center(child: Text('ledgerNoTransactions'.tr)),
        );
      }

      final isTaken = tx.isTaken;
      final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;
      final personName = controller.selectedPerson?.name ?? '';
      final balanceColor = controller.balanceColor(tx.balanceAfter);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              personName,
              style: TextStyle(
                color: LedgerColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 17.sp,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: LedgerColors.primaryBlue,
            elevation: 0,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.formatTransactionTime(tx),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                tx.typeLabel,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                LedgerFormat.shekel1(tx.amount),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: balanceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: balanceColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              LedgerFormat.labeled(
                                'ledgerBalance'.tr,
                                tx.balanceAfter,
                                fractionDigits: 1,
                              ),
                              style: TextStyle(
                                color: balanceColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          if (tx.isInstantSale) ...[
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16.sp,
                                  color: LedgerColors.takenGreen,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'ledgerInstantSaleTag'.tr,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 28.w),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: LedgerColors.cardBlue,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () => controller.openEditTransaction(tx),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 48.w,
                                height: 48.w,
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: LedgerColors.primaryBlue,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'edit'.tr,
                            style: TextStyle(
                              color: LedgerColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LedgerColors.givenRed,
                              side: BorderSide(color: LedgerColors.givenRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () =>
                                controller.deleteTransaction(tx.id),
                            child: Text(
                              'delete'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LedgerColors.primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () =>
                                controller.archiveTransactionFromDetail(tx.id),
                            child: Text(
                              'ledgerArchive'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LedgerColors.primaryBlue,
                        side: BorderSide(
                          color: LedgerColors.primaryBlue.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () =>
                          controller.openTransactionShareSheet(tx),
                      icon: Icon(Icons.share_outlined, size: 20.sp),
                      label: Text(
                        'Share'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
