import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_currency_tab_bar.dart';
import 'ledger_format.dart';

class PersonDeletedScreen extends StatefulWidget {
  const PersonDeletedScreen({Key? key}) : super(key: key);

  @override
  State<PersonDeletedScreen> createState() => _PersonDeletedScreenState();
}

class _PersonDeletedScreenState extends State<PersonDeletedScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<DebtLedgerController>().loadPersonDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: Text(
            'ledgerDeletedTitle'.tr,
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
        body: Obx(() {
          if (controller.personDeletedLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = controller.personDeletedDetail.value;
          if (detail == null) {
            return Center(child: Text('ledgerNoTransactions'.tr));
          }

          final cur = controller.selectedCurrency.value;
          final stats = detail.balanceFor(cur);
          final balanceColor = controller.balanceColor(stats.balance);
          final typeHint = stats.balance >= 0 ? 'took'.tr : 'gave'.tr;

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              LedgerCurrencyTabBar(
                selected: cur,
                onSelected: (currency) {
                  controller.changeCurrency(currency);
                  controller.loadPersonDeleted();
                },
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'ledgerDeletedHint'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'ledgerDeletedBalance'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: LedgerColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      typeHint,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      LedgerFormat.money(
                        stats.balance.abs(),
                        currency: cur,
                        fractionDigits: 1,
                      ),
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${'ledgerTransactions'.tr} (${detail.transactions.length}) — $cur',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: LedgerColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    if (detail.transactions.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text('ledgerDeletedEmpty'.tr),
                      )
                    else
                      ...detail.transactions.map((tx) {
                        return Column(
                          children: [
                            const Divider(height: 1),
                            _DeletedRow(
                              transaction: tx,
                              timeLabel:
                                  controller.formatTransactionTime(tx),
                            ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DeletedRow extends StatelessWidget {
  final LedgerTransaction transaction;
  final String timeLabel;

  const _DeletedRow({
    required this.transaction,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = transaction.isTaken;
    final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LedgerFormat.money(
                    transaction.amount,
                    currency: transaction.currency,
                    fractionDigits: 1,
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  transaction.typeLabel,
                  style: TextStyle(fontSize: 12.sp, color: color),
                ),
                if (transaction.note != null &&
                    transaction.note!.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    transaction.note!,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                LedgerFormat.labeled(
                  'ledgerBalance'.tr,
                  transaction.balanceAfter,
                  currency: transaction.currency,
                  fractionDigits: 1,
                ),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
