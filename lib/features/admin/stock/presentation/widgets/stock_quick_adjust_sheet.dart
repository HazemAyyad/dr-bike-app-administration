import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';

class StockQuickAdjustResult {
  final int quantity;
  final String? note;

  const StockQuickAdjustResult({required this.quantity, this.note});
}

Future<StockQuickAdjustResult?> showStockQuickAdjustSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  int currentStock = 0,
}) {
  return showModalBottomSheet<StockQuickAdjustResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StockQuickAdjustSheet(
      title: title,
      subtitle: subtitle,
      currentStock: currentStock,
    ),
  );
}

class _StockQuickAdjustSheet extends StatefulWidget {
  const _StockQuickAdjustSheet({
    required this.title,
    this.subtitle,
    required this.currentStock,
  });

  final String title;
  final String? subtitle;
  final int currentStock;

  @override
  State<_StockQuickAdjustSheet> createState() => _StockQuickAdjustSheetState();
}

class _StockQuickAdjustSheetState extends State<_StockQuickAdjustSheet> {
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  bool _subtract = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_qtyController.text.trim());
    if (parsed == null || parsed < 1) {
      Get.snackbar('error'.tr, 'invalidQuantity'.tr);
      return;
    }
    final signed = _subtract ? -parsed : parsed;
    Navigator.of(context).pop(
      StockQuickAdjustResult(
        quantity: signed,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'addStockQuick'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AdminUiColors.subtleOverlay(context),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${'stock'.tr}: ${widget.currentStock}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text('stockAdjustAdd'.tr),
                          icon: const Icon(Icons.add, size: 16),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('stockAdjustRemove'.tr),
                          icon: const Icon(Icons.remove, size: 16),
                        ),
                      ],
                      selected: {_subtract},
                      onSelectionChanged: (s) {
                        setState(() => _subtract = s.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'quantity'.tr,
                  filled: true,
                  fillColor: AdminUiColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'notes'.tr,
                  filled: true,
                  fillColor: AdminUiColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'save'.tr,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
