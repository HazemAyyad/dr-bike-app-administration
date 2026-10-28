import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';

class SalesDailyTransferCorrectionSheet extends StatefulWidget {
  const SalesDailyTransferCorrectionSheet({
    Key? key,
    required this.request,
    required this.datasource,
    required this.returnToReview,
    this.boxes = const [],
  }) : super(key: key);

  final DailyClosingHistoryModel request;
  final SalesDatasource datasource;
  final bool returnToReview;
  final List<ShownBoxesModel> boxes;

  @override
  State<SalesDailyTransferCorrectionSheet> createState() =>
      _SalesDailyTransferCorrectionSheetState();
}

class _SalesDailyTransferCorrectionSheetState
    extends State<SalesDailyTransferCorrectionSheet> {
  final _reason = TextEditingController();
  final _targets = <String, ShownBoxesModel>{};
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencies =
        widget.request.transfers.map((row) => '${row['currency']}').toSet();
    return PopScope(
      canPop: !_submitting,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w,
              MediaQuery.of(context).viewInsets.bottom + 16.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    widget.returnToReview
                        ? 'عكس الإغلاق وإعادة الطلب للمراجعة'
                        : 'تصحيح صندوق الترحيل',
                    style: TextStyle(
                        fontSize: 17.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.h),
                Text(widget.returnToReview
                    ? 'سيُسحب مبلغ الترحيل من صندوق الوجهة ويُعاد للصندوق اليومي، ويبقى طلب الإغلاق بانتظار المراجعة والاعتماد مجددًا.'
                    : 'سيُنقل المبلغ من صندوق الوجهة الحالي إلى الصندوق الذي تختاره. تبقى الجلسة مغلقة وتُحفظ العملية الأصلية والتصحيح في السجل.'),
                ...widget.request.transfers.map((row) => Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                          '${row['amount']} ${row['currency']} — الوجهة الحالية: '
                          '${row['to_box_name'] ?? '#${row['to_box_id']}'}'),
                    )),
                if (!widget.returnToReview)
                  ...currencies.map((currency) => Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: CustomDropdownFieldWithSearch(
                          tital: 'صندوق الوجهة الجديد — $currency',
                          hint: 'اختر الصندوق',
                          items: widget.boxes
                              .where((box) =>
                                  box.currency == currency &&
                                  box.isShown &&
                                  ![
                                    'daily_sales',
                                    'daily_sales_orders',
                                    'daily_maintenance'
                                  ].contains(box.type))
                              .toList(),
                          value: _targets[currency],
                          isEnabled: !_submitting,
                          onChanged: (value) => setState(() {
                            if (value is ShownBoxesModel) {
                              _targets[currency] = value;
                            }
                          }),
                          itemAsString: (item) =>
                              (item as ShownBoxesModel).boxName,
                          compareFn: (a, b) =>
                              (a as ShownBoxesModel).boxId ==
                              (b as ShownBoxesModel).boxId,
                        ),
                      )),
                SizedBox(height: 12.h),
                TextField(
                  controller: _reason,
                  enabled: !_submitting,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'سبب التصحيح (مطلوب)'),
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                SizedBox(height: 12.h),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'جارٍ الحفظ...' : 'تأكيد العملية'),
                ),
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final currencies =
        widget.request.transfers.map((row) => '${row['currency']}').toSet();
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'أدخل سبب التصحيح.');
      return;
    }
    if (!widget.returnToReview &&
        currencies.any((currency) => !_targets.containsKey(currency))) {
      setState(() => _error = 'اختر صندوق الوجهة لكل عملة.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.datasource.correctDailyClosingTransfer(
        closingRequestId: widget.request.id,
        action: widget.returnToReview ? 'return_to_review' : 'redirect',
        reason: _reason.text,
        transfers: _targets.entries
            .map((entry) => <String, dynamic>{
                  'currency': entry.key,
                  'to_box_id': entry.value.boxId,
                })
            .toList(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }
}
