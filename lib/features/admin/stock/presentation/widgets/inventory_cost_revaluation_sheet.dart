import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/app_failure_notice.dart';

class InventoryCostRevaluationResult {
  const InventoryCostRevaluationResult({
    required this.newUnitCost,
    required this.reason,
    this.notes,
  });

  final double newUnitCost;
  final String reason;
  final String? notes;
}

Future<InventoryCostRevaluationResult?> showInventoryCostRevaluationSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  double? currentUnitCost,
  String currency = 'شيكل',
  bool initializeMissingCost = false,
}) {
  return showModalBottomSheet<InventoryCostRevaluationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InventoryCostRevaluationSheet(
      title: title,
      subtitle: subtitle,
      currentUnitCost: currentUnitCost,
      currency: currency,
      initializeMissingCost: initializeMissingCost,
    ),
  );
}

class _InventoryCostRevaluationSheet extends StatefulWidget {
  const _InventoryCostRevaluationSheet({
    required this.title,
    this.subtitle,
    this.currentUnitCost,
    required this.currency,
    required this.initializeMissingCost,
  });

  final String title;
  final String? subtitle;
  final double? currentUnitCost;
  final String currency;
  final bool initializeMissingCost;

  @override
  State<_InventoryCostRevaluationSheet> createState() =>
      _InventoryCostRevaluationSheetState();
}

class _InventoryCostRevaluationSheetState
    extends State<_InventoryCostRevaluationSheet> {
  late final TextEditingController costController;
  final reasonController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final current = widget.currentUnitCost;
    costController = TextEditingController(
      text: current == null ? '' : current.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    costController.dispose();
    reasonController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void submit() {
    final cost =
        double.tryParse(costController.text.trim().replaceAll(',', '.'));
    final reason = reasonController.text.trim();
    if (cost == null || (widget.initializeMissingCost ? cost <= 0 : cost < 0)) {
      AppFailureNotice.show(title: 'خطأ', message: 'أدخل تكلفة وحدة صحيحة.');
      return;
    }
    if (reason.isEmpty) {
      AppFailureNotice.show(
        title: 'خطأ',
        message: widget.initializeMissingCost
            ? 'سبب إدخال التكلفة مطلوب.'
            : 'سبب إعادة التقييم مطلوب.',
      );
      return;
    }
    Navigator.of(context).pop(
      InventoryCostRevaluationResult(
        newUnitCost: cost,
        reason: reason,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initializeMissingCost
                          ? 'إدخال تكلفة المخزون الناقصة'
                          : 'إعادة تقييم تكلفة المخزون',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (widget.subtitle?.isNotEmpty == true) Text(widget.subtitle!),
              const SizedBox(height: 8),
              Text(
                widget.initializeMissingCost
                    ? 'سيتم إنشاء تغطية محاسبية للكمية الناقصة فقط، من دون تغيير كمية المخزون.'
                    : 'هذه العملية لا تغيّر الكمية؛ تسجل فرق القيمة وسجل التدقيق فقط.',
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.initializeMissingCost
                      ? 'تكلفة وحدة المخزون الناقص'
                      : 'تكلفة الوحدة الجديدة',
                  suffixText: widget.currency,
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: widget.initializeMissingCost
                      ? 'سبب إدخال التكلفة'
                      : 'سبب إعادة التقييم',
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 14.h),
              FilledButton(
                onPressed: submit,
                child: Text(widget.initializeMissingCost
                    ? 'تسجيل تكلفة المخزون'
                    : 'تسجيل إعادة التقييم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
