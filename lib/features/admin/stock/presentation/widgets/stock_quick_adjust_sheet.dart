import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/app_failure_notice.dart';

class StockQuickAdjustResult {
  final int actualQuantity;
  final String reason;
  final String? notes;
  final double? unitCost;

  const StockQuickAdjustResult({
    required this.actualQuantity,
    required this.reason,
    this.notes,
    this.unitCost,
  });
}

Future<StockQuickAdjustResult?> showStockQuickAdjustSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  int currentStock = 0,
  String currency = 'شيكل',
}) {
  return showModalBottomSheet<StockQuickAdjustResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockQuickAdjustSheet(
      title: title,
      subtitle: subtitle,
      currentStock: currentStock,
      currency: currency,
    ),
  );
}

class _StockQuickAdjustSheet extends StatefulWidget {
  const _StockQuickAdjustSheet({
    required this.title,
    required this.currentStock,
    required this.currency,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int currentStock;
  final String currency;

  @override
  State<_StockQuickAdjustSheet> createState() => _StockQuickAdjustSheetState();
}

class _StockQuickAdjustSheetState extends State<_StockQuickAdjustSheet> {
  static const reasons = <String>[
    'جرد فعلي للمخزون',
    'مخزون قديم غير مسجل',
    'تصحيح مخزون فعلي',
    'بضاعة مورد غير مدخلة سابقاً',
    'تصحيح مخزون افتتاحي',
    'تالف أو مفقود',
    'أخرى',
  ];

  late final TextEditingController actualController;
  final costController = TextEditingController();
  final notesController = TextEditingController();
  String reason = reasons.first;

  int? get actual => int.tryParse(actualController.text.trim());
  int? get difference => actual == null ? null : actual! - widget.currentStock;

  @override
  void initState() {
    super.initState();
    actualController = TextEditingController(text: '${widget.currentStock}');
    actualController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    actualController.removeListener(_refresh);
    actualController.dispose();
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void submit() {
    final counted = actual;
    final diff = difference;
    if (counted == null || counted < 0 || diff == 0) {
      AppFailureNotice.show(
        title: 'خطأ',
        message: diff == 0
            ? 'الكمية الفعلية مطابقة لكمية النظام.'
            : 'أدخل كمية فعلية صحيحة.',
      );
      return;
    }
    final unitCost = double.tryParse(costController.text.trim());
    if (diff! > 0 && (unitCost == null || unitCost < 0)) {
      AppFailureNotice.show(
        title: 'خطأ',
        message: 'تكلفة الوحدة مطلوبة عند زيادة المخزون.',
      );
      return;
    }
    Navigator.of(context).pop(StockQuickAdjustResult(
      actualQuantity: counted,
      reason: reason,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      unitCost: diff > 0 ? unitCost : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diff = difference;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text('تسوية المخزون',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (widget.subtitle?.isNotEmpty == true) Text(widget.subtitle!),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                    color: AdminUiColors.subtleOverlay(context),
                    borderRadius: BorderRadius.circular(10.r)),
                child: Row(children: [
                  Expanded(child: Text('كمية النظام: ${widget.currentStock}')),
                  Text(
                      'الفرق: ${diff == null ? '—' : diff > 0 ? '+$diff' : '$diff'}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: diff == null || diff == 0
                              ? cs.onSurface
                              : diff > 0
                                  ? Colors.green
                                  : cs.error)),
                ]),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: actualController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'الكمية الفعلية بعد الجرد',
                    border: OutlineInputBorder()),
              ),
              if ((diff ?? 0) > 0) ...[
                SizedBox(height: 10.h),
                TextField(
                  controller: costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'تكلفة الوحدة',
                      suffixText: widget.currency,
                      border: const OutlineInputBorder()),
                ),
              ],
              SizedBox(height: 10.h),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(
                    labelText: 'السبب', border: OutlineInputBorder()),
                items: reasons
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => reason = v ?? reasons.first),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder()),
              ),
              SizedBox(height: 14.h),
              FilledButton(
                  onPressed: submit, child: const Text('تسجيل التسوية')),
            ],
          ),
        ),
      ),
    );
  }
}
