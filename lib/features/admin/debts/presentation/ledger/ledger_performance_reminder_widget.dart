import 'package:flutter/material.dart';

import '../../../../../core/utils/assets_manger.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';
import 'ledger_share_pattern.dart';

/// WhatsApp share card for «تذكير بالأداء».
class LedgerPerformanceReminderWidget extends StatelessWidget {
  static const double cardWidth = 400;
  static const double cardHeight = 520;

  final String personName;
  final String timeLabel;
  final String reminderTitle;
  final double balance;
  final double totalTaken;
  final double totalGiven;
  final int takenCount;
  final int givenCount;
  final String takenLabel;
  final String givenLabel;
  final String transactionsWord;

  const LedgerPerformanceReminderWidget({
    Key? key,
    required this.personName,
    required this.timeLabel,
    required this.reminderTitle,
    required this.balance,
    required this.totalTaken,
    required this.totalGiven,
    required this.takenCount,
    required this.givenCount,
    required this.takenLabel,
    required this.givenLabel,
    required this.transactionsWord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        balance >= 0 ? LedgerColors.givenRed : LedgerColors.takenGreen;
    final displayBalance = balance.abs();

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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _line(personName, 22, FontWeight.w600,
                          LedgerColors.primaryBlue),
                      const SizedBox(height: 6),
                      _line(
                        timeLabel,
                        14,
                        FontWeight.normal,
                        LedgerColors.primaryBlue.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 22),
                      _line(reminderTitle, 18, FontWeight.bold,
                          const Color(0xFF1A3A6B)),
                      const SizedBox(height: 10),
                      _line(
                        LedgerFormat.shekel2(displayBalance),
                        40,
                        FontWeight.bold,
                        balanceColor,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryColumn(
                              color: LedgerColors.givenRed,
                              icon: Icons.south_east,
                              amount: totalGiven,
                              count: givenCount,
                              label: givenLabel,
                              transactionsWord: transactionsWord,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryColumn(
                              color: LedgerColors.takenGreen,
                              icon: Icons.north_east,
                              amount: totalTaken,
                              count: takenCount,
                              label: takenLabel,
                              transactionsWord: transactionsWord,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        AssetsManager.whiteLogo,
                        width: 360,
                        height: 200,
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

  Widget _line(String text, double size, FontWeight weight, Color color) {
    return SizedBox(
      width: cardWidth - 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double amount;
  final int count;
  final String label;
  final String transactionsWord;

  const _SummaryColumn({
    required this.color,
    required this.icon,
    required this.amount,
    required this.count,
    required this.label,
    required this.transactionsWord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          LedgerFormat.shekel1(amount),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 12, color: color),
        ),
        Text(
          '$count $transactionsWord',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
