import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/stock_movements_filters.dart';

class StockMovementsFilterSheet extends StatefulWidget {
  const StockMovementsFilterSheet({
    Key? key,
    required this.initial,
  }) : super(key: key);

  final StockMovementsFilters initial;

  @override
  State<StockMovementsFilterSheet> createState() =>
      _StockMovementsFilterSheetState();
}

class _StockMovementsFilterSheetState extends State<StockMovementsFilterSheet> {
  DateTime? dateFrom;
  DateTime? dateTo;
  String? type;

  static const _typeOptions = <String?, String>{
    null: 'stockMoveFilterAllTypes',
    'sale': 'stockMoveTypeSale',
    'sale_cancel': 'stockMoveTypeSaleCancel',
    'purchase': 'stockMoveTypePurchase',
    'bill_quantity': 'stockMoveTypeBillQuantity',
    'destruction': 'stockMoveTypeDestruction',
    'return': 'stockMoveTypeReturn',
    'manual_add': 'stockMoveTypeManualAdd',
    'manual_set': 'stockMoveTypeManualSet',
    'import': 'stockMoveTypeImport',
  };

  @override
  void initState() {
    super.initState();
    dateFrom = widget.initial.dateFrom;
    dateTo = widget.initial.dateTo;
    type = widget.initial.type;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? dateFrom : dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        dateFrom = picked;
      } else {
        dateTo = picked;
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      StockMovementsFilters(
        dateFrom: dateFrom,
        dateTo: dateTo,
        type: type,
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(const StockMovementsFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        24.h + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'filters'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: 14.h),
            DropdownButtonFormField<String?>(
              value: type,
              decoration: InputDecoration(
                labelText: 'stockMoveFilterType'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              items: _typeOptions.entries
                  .map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value.tr),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => type = v),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: true),
              icon: const Icon(Icons.date_range),
              label: Text(
                dateFrom == null
                    ? 'from'.tr
                    : '${'from'.tr}: ${StockMovementsFilters.formatDisplayDate(dateFrom!)}',
              ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: false),
              icon: const Icon(Icons.date_range),
              label: Text(
                dateTo == null
                    ? 'to'.tr
                    : '${'to'.tr}: ${StockMovementsFilters.formatDisplayDate(dateTo!)}',
              ),
            ),
            SizedBox(height: 18.h),
            AppButton(
              text: 'apply'.tr,
              onPressed: _apply,
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _clear,
              child: Text(
                'clearFilters'.tr,
                style: TextStyle(color: AppColors.redColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<StockMovementsFilters?> showStockMovementsFilterSheet({
  required BuildContext context,
  required StockMovementsFilters initial,
}) {
  return showModalBottomSheet<StockMovementsFilters>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StockMovementsFilterSheet(initial: initial),
  );
}
