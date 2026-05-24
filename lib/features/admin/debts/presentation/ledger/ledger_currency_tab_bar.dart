import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'ledger_colors.dart';
import 'ledger_format.dart';

/// شريط تبويب عملات (شيكل / دولار / دينار) لشاشة الديون والعميل.
class LedgerCurrencyTabBar extends StatelessWidget {
  const LedgerCurrencyTabBar({
    Key? key,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  static const List<String> currencies = ['شيكل', 'دولار', 'دينار'];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: currencies.map((currency) {
          final isSelected = selected == currency;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(currency),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? LedgerColors.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${LedgerFormat.symbolFor(currency)} $currency',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
