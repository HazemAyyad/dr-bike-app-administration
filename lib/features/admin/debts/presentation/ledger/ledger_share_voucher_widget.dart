import 'package:flutter/material.dart';

import '../../../../../core/utils/assets_manger.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';
import 'ledger_share_pattern.dart';

/// Konnash-style voucher for WhatsApp share (fixed logical size for image capture).
class LedgerShareVoucherWidget extends StatelessWidget {
  static const double cardWidth = 400;
  static const double cardHeight = 560;

  final String personName;
  final String timeLabel;
  final String transactionValueLabel;
  final double amount;
  final bool isTaken;

  const LedgerShareVoucherWidget({
    Key? key,
    required this.personName,
    required this.timeLabel,
    required this.transactionValueLabel,
    required this.amount,
    required this.isTaken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amountColor =
        isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const LedgerShareGeometricPattern(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _centeredText(
                        personName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: LedgerColors.primaryBlue,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _centeredText(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: LedgerColors.primaryBlue.withValues(alpha: 0.65),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _centeredText(
                        transactionValueLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A6B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _centeredText(
                        LedgerFormat.shekel2(amount),
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Image.asset(
                        AssetsManager.whiteLogo,
                        width: 360,
                        height: 240,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centeredText(String text, {required TextStyle style}) {
    return SizedBox(
      width: cardWidth - 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: style,
      ),
    );
  }
}
