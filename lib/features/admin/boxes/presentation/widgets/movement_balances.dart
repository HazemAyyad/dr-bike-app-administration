import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entity/all_boxes_logs_entity.dart';

/// Balances supplied by the server from the complete ledger, before filtering.
class MovementBalances extends StatelessWidget {
  const MovementBalances({Key? key, required this.log}) : super(key: key);

  final BoxLog log;

  @override
  Widget build(BuildContext context) {
    final rows = <String>[];
    String amount(double? value) =>
        value == null ? '—' : NumberFormat('#,##0.##').format(value);
    void add(String label, double? before, double? after) {
      rows.add('$label قبل: ${amount(before)}  |  بعد: ${amount(after)}');
    }

    if (log.boxBalanceBefore != null || log.boxBalanceAfter != null) {
      add('الرصيد', log.boxBalanceBefore, log.boxBalanceAfter);
    } else if (log.type == 'transfer') {
      if (log.fromBoxBalanceBefore != null || log.fromBoxBalanceAfter != null) {
        add('من ${log.fromBox?.name ?? 'الصندوق المرسل'}:',
            log.fromBoxBalanceBefore, log.fromBoxBalanceAfter);
      }
      if (log.toBoxBalanceBefore != null || log.toBoxBalanceAfter != null) {
        add('إلى ${log.toBox?.name ?? 'الصندوق المستقبِل'}:',
            log.toBoxBalanceBefore, log.toBoxBalanceAfter);
      }
    }
    if (rows.isEmpty) rows.add('الرصيد قبل: —  |  بعد: —');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map((row) => Text(row,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )))
            .toList(),
      ),
    );
  }
}
