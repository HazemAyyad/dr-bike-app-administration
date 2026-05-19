import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';

class ArchiveTransactionsSheet extends StatefulWidget {
  final List<LedgerTransaction> transactions;

  const ArchiveTransactionsSheet({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<ArchiveTransactionsSheet> createState() => _ArchiveTransactionsSheetState();
}

class _ArchiveTransactionsSheetState extends State<ArchiveTransactionsSheet> {
  final Set<int> _selected = <int>{};
  bool _isArchiving = false;

  bool get _allSelected =>
      widget.transactions.isNotEmpty &&
      _selected.length == widget.transactions.length;

  void _toggleAll(bool? value) {
    setState(() {
      if (value == true) {
        _selected.addAll(widget.transactions.map((e) => e.id));
      } else {
        _selected.clear();
      }
    });
  }

  Future<void> _archive() async {
    if (_selected.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerSelectTransactions'.tr);
      return;
    }

    setState(() => _isArchiving = true);
    final ok = await Get.find<DebtLedgerController>()
        .archiveTransactionsBulk(_selected.toList());
    setState(() => _isArchiving = false);

    if (ok && mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'ledgerArchive'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: LedgerColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    '${'ledgerTransactions'.tr} (${widget.transactions.length})',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: LedgerColors.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: _allSelected,
                    tristate: false,
                    onChanged: _toggleAll,
                    activeColor: LedgerColors.primaryBlue,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.transactions.isEmpty
                  ? Center(child: Text('ledgerNoTransactions'.tr))
                  : ListView.separated(
                      itemCount: widget.transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = widget.transactions[index];
                        return _ArchiveSelectableRow(
                          transaction: tx,
                          timeLabel: controller.formatTransactionTime(tx),
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
                        );
                      },
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
                      backgroundColor: const Color(0xFFFF8A80),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isArchiving ? null : _archive,
                    child: _isArchiving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'ledgerArchiveSelected'.tr,
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
        ),
      ),
    );
  }
}

class _ArchiveSelectableRow extends StatelessWidget {
  final LedgerTransaction transaction;
  final String timeLabel;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _ArchiveSelectableRow({
    required this.transaction,
    required this.timeLabel,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = transaction.isTaken;
    final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
