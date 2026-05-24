import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'ledger_colors.dart';
import 'ledger_format.dart';

class LedgerCurrencyChips extends StatelessWidget {
  const LedgerCurrencyChips({
    Key? key,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  static const List<String> currencies = ['شيكل', 'دولار', 'دينار'];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ledgerCurrency'.tr,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children: currencies.map((currency) {
            final isSelected = selected == currency;
            return ChoiceChip(
              label: Text(
                '${LedgerFormat.symbolFor(currency)} $currency',
              ),
              selected: isSelected,
              selectedColor: LedgerColors.primaryBlue.withValues(alpha: 0.15),
              onSelected: (_) => onSelected(currency),
            );
          }).toList(),
        ),
      ],
    );
  }
}
