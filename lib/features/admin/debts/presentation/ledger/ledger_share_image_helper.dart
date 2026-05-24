import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import 'ledger_performance_reminder_widget.dart';
import 'ledger_share_voucher_widget.dart';

class LedgerShareImageHelper {
  static final ScreenshotController _controller = ScreenshotController();

  static Future<Uint8List?> captureTransactionVoucher({
    required String personName,
    required String timeLabel,
    required String transactionValueLabel,
    required double amount,
    required bool isTaken,
  }) async {
    try {
      return await _controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: Colors.transparent,
            child: LedgerShareVoucherWidget(
              personName: personName,
              timeLabel: timeLabel,
              transactionValueLabel: transactionValueLabel,
              amount: amount,
              isTaken: isTaken,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 120),
        pixelRatio: 3,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> capturePerformanceReminder({
    required String personName,
    required String timeLabel,
    required String reminderTitle,
    required double balance,
    required double totalTaken,
    required double totalGiven,
    required int takenCount,
    required int givenCount,
    required String takenLabel,
    required String givenLabel,
    required String transactionsWord,
    String currency = 'شيكل',
  }) async {
    try {
      return await _controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: Colors.transparent,
            child: LedgerPerformanceReminderWidget(
              personName: personName,
              timeLabel: timeLabel,
              reminderTitle: reminderTitle,
              balance: balance,
              totalTaken: totalTaken,
              totalGiven: totalGiven,
              takenCount: takenCount,
              givenCount: givenCount,
              takenLabel: takenLabel,
              givenLabel: givenLabel,
              transactionsWord: transactionsWord,
              currency: currency,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 120),
        pixelRatio: 3,
      );
    } catch (_) {
      return null;
    }
  }
}
