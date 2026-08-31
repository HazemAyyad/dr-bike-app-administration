import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/boxes_controller.dart';

class BoxReportFilterSheet extends StatefulWidget {
  const BoxReportFilterSheet({
    Key? key,
    required this.boxId,
    required this.boxName,
  }) : super(key: key);

  final String boxId;
  final String boxName;

  @override
  State<BoxReportFilterSheet> createState() => _BoxReportFilterSheetState();
}

class _BoxReportFilterSheetState extends State<BoxReportFilterSheet> {
  final controller = Get.find<BoxesController>();
  final _types = const <String, String>{
    'add': 'إضافة رصيد',
    'minus': 'سحب رصيد',
    'transfer': 'تحويل',
    'sale': 'مبيعات',
    'maintenance': 'صيانة',
    'expense': 'مصاريف',
    'payroll': 'رواتب',
    'settlement': 'تسويات',
    'cancellation_reversal': 'إلغاء / عكس حركة',
  };

  @override
  void initState() {
    super.initState();
    if (controller.fromDateController.text.isEmpty) {
      _quickRange('month');
    }
  }

  String _format(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void _quickRange(String range) {
    final now = DateTime.now();
    final DateTime from;
    if (range == 'today') {
      from = DateTime(now.year, now.month, now.day);
    } else if (range == 'week') {
      from = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
    } else if (range == 'year') {
      from = DateTime(now.year);
    } else {
      from = DateTime(now.year, now.month);
    }
    setState(() {
      controller.fromDateController.text = _format(from);
      controller.toDateController.text = _format(now);
    });
  }

  Future<void> _pickDate(TextEditingController target) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(target.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => target.text = _format(selected));
  }

  Future<void> _export(String action) async {
    final from = DateTime.tryParse(controller.fromDateController.text);
    final to = DateTime.tryParse(controller.toDateController.text);
    final min = double.tryParse(controller.reportMinAmountController.text);
    final max = double.tryParse(controller.reportMaxAmountController.text);
    if (from == null || to == null || to.isBefore(from)) {
      Get.snackbar('تنبيه', 'اختر فترة صحيحة للتقرير');
      return;
    }
    if (min != null && max != null && max < min) {
      Get.snackbar('تنبيه', 'الحد الأعلى يجب أن يكون أكبر من الحد الأدنى');
      return;
    }
    await controller.downloadReport(
      context: context,
      boxId: widget.boxId,
      boxName: widget.boxName,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'تقرير صندوق ${widget.boxName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
            ),
            const SizedBox(height: 6),
            const Text('الفلاتر المطبقة هنا ستظهر نفسها داخل ملف PDF.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                    label: const Text('اليوم'),
                    onPressed: () => _quickRange('today')),
                ActionChip(
                    label: const Text('هذا الأسبوع'),
                    onPressed: () => _quickRange('week')),
                ActionChip(
                    label: const Text('هذا الشهر'),
                    onPressed: () => _quickRange('month')),
                ActionChip(
                    label: const Text('هذه السنة'),
                    onPressed: () => _quickRange('year')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child:
                        _dateField('من تاريخ', controller.fromDateController)),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _dateField('إلى تاريخ', controller.toDateController)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: controller.reportDirection.value,
              decoration: const InputDecoration(labelText: 'اتجاه الحركة'),
              items: const [
                DropdownMenuItem(value: '', child: Text('الكل')),
                DropdownMenuItem(value: 'incoming', child: Text('وارد')),
                DropdownMenuItem(value: 'outgoing', child: Text('صادر')),
                DropdownMenuItem(value: 'transfer', child: Text('تحويلات')),
              ],
              onChanged: (value) =>
                  controller.reportDirection.value = value ?? '',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.reportSearchController,
              decoration: const InputDecoration(
                labelText: 'بحث في البيان أو الملاحظة أو رقم الحركة',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _amountField(
                        'أقل مبلغ', controller.reportMinAmountController)),
                const SizedBox(width: 10),
                Expanded(
                    child: _amountField(
                        'أعلى مبلغ', controller.reportMaxAmountController)),
              ],
            ),
            const SizedBox(height: 14),
            const Text('أنواع الحركات',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Obx(
              () => Wrap(
                spacing: 7,
                runSpacing: 6,
                children: _types.entries.map((entry) {
                  final selected =
                      controller.reportMovementTypes.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) => selected
                        ? controller.reportMovementTypes.remove(entry.key)
                        : controller.reportMovementTypes.add(entry.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export('share'),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('مشاركة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export('print'),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('معاينة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _export('save'),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, TextEditingController textController) {
    return TextField(
      controller: textController,
      readOnly: true,
      onTap: () => _pickDate(textController),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
    );
  }

  Widget _amountField(String label, TextEditingController textController) {
    return TextField(
      controller: textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}
