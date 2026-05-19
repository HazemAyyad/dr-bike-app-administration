import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';

class PersonArchiveScreen extends StatefulWidget {
  const PersonArchiveScreen({Key? key}) : super(key: key);

  @override
  State<PersonArchiveScreen> createState() => _PersonArchiveScreenState();
}

class _PersonArchiveScreenState extends State<PersonArchiveScreen> {
  final Set<int> _selected = <int>{};
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    Get.find<DebtLedgerController>().loadPersonArchive();
  }

  bool _allSelected(List<LedgerTransaction> list) =>
      list.isNotEmpty && _selected.length == list.length;

  void _toggleAll(List<LedgerTransaction> list, bool? value) {
    setState(() {
      if (value == true) {
        _selected.addAll(list.map((e) => e.id));
      } else {
        _selected.clear();
      }
    });
  }

  Future<void> _restoreSelected() async {
    if (_selected.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerSelectTransactions'.tr);
      return;
    }

    setState(() => _isRestoring = true);
    final ok = await Get.find<DebtLedgerController>()
        .restoreTransactionsBulk(_selected.toList());
    setState(() => _isRestoring = false);

    if (ok) {
      setState(() => _selected.clear());
    }
  }

  Future<void> _restoreOne(int id) async {
    setState(() => _isRestoring = true);
    await Get.find<DebtLedgerController>().restoreTransactionsBulk([id]);
    setState(() => _isRestoring = false);
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
            'ledgerArchiveTitle'.tr,
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
          if (controller.personArchiveLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = controller.personArchiveDetail.value;
          if (detail == null) {
            return Center(child: Text('ledgerNoTransactions'.tr));
          }

          final balanceColor = controller.balanceColor(detail.balance);
          final typeHint = detail.balance >= 0 ? 'took'.tr : 'gave'.tr;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  children: [
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
                            'ledgerArchiveBalance'.tr,
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
                            LedgerFormat.shekel1(detail.balance.abs()),
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
                            child: Row(
                              children: [
                                Text(
                                  '${'ledgerTransactions'.tr} (${detail.transactions.length})',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: LedgerColors.primaryBlue,
                                  ),
                                ),
                                const Spacer(),
                                Checkbox(
                                  value: _allSelected(detail.transactions),
                                  onChanged: (v) =>
                                      _toggleAll(detail.transactions, v),
                                  activeColor: LedgerColors.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                          if (detail.transactions.isEmpty)
                            Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Text('ledgerNoTransactions'.tr),
                            )
                          else
                            ...detail.transactions.map((tx) {
                              return Column(
                                children: [
                                  const Divider(height: 1),
                                  _ArchivedRow(
                                    transaction: tx,
                                    timeLabel:
                                        controller.formatTransactionTime(tx),
                                    selected: _selected.contains(tx.id),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(tx.id);
                                        } else {
                                          _selected.remove(tx.id);
                                        }
                                      });
                                    },
                                    onRestore: _isRestoring
                                        ? null
                                        : () => _restoreOne(tx.id),
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LedgerColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _isRestoring ? null : _restoreSelected,
                      child: _isRestoring
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ledgerReturnToAccount'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  final LedgerTransaction transaction;
  final String timeLabel;
  final bool selected;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onRestore;

  const _ArchivedRow({
    required this.transaction,
    required this.timeLabel,
    required this.selected,
    required this.onChanged,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = transaction.isTaken;
    final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LedgerFormat.shekel1(transaction.amount),
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
                ],
              ),
            ),
            if (onRestore != null)
              IconButton(
                onPressed: onRestore,
                icon: Icon(
                  Icons.restore,
                  color: LedgerColors.givenRed,
                  size: 22.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            SizedBox(width: 8.w),
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
                    fractionDigits: 1,
                  ),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            Checkbox(
              value: selected,
              onChanged: onChanged,
              activeColor: LedgerColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
