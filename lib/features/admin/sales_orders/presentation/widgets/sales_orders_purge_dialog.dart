import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/sales_orders_controller.dart';
import 'sales_orders_purge_backups_dialog.dart';

class SalesOrdersPurgeDialog extends StatefulWidget {
  const SalesOrdersPurgeDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SalesOrdersController controller;

  static Future<void> show(
    BuildContext context,
    SalesOrdersController controller,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SalesOrdersPurgeDialog(controller: controller),
    );
  }

  @override
  State<SalesOrdersPurgeDialog> createState() => _SalesOrdersPurgeDialogState();
}

class _SalesOrdersPurgeDialogState extends State<SalesOrdersPurgeDialog> {
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime _before = DateTime.now();
  Map<String, dynamic>? _preview;
  bool _loading = true;
  bool _deleting = false;
  String _mode = 'orders_only_reset';

  String get _beforeText => DateFormat('yyyy-MM-dd').format(_before);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await widget.controller.loadPurgePreview(_beforeText, _mode);
    if (!mounted) return;
    setState(() {
      _preview = data;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _before,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'احذف الطلبيات حتى تاريخ',
    );
    if (selected == null || !mounted) return;
    setState(() => _before = selected);
    await _loadPreview();
  }

  Future<void> _selectMode(String value) async {
    if (_loading || _deleting || value == _mode) return;
    setState(() => _mode = value);
    await _loadPreview();
  }

  Future<void> _purge() async {
    final preview = _preview;
    if (preview == null) return;
    if (_confirmationController.text.trim() != 'DELETE') {
      Get.snackbar('تنبيه', 'اكتب DELETE للتأكيد');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'أدخل كلمة مرور الأدمن');
      return;
    }

    setState(() => _deleting = true);
    final deleted = await widget.controller.purgeTestOrders(
      before: _beforeText,
      maxOrderId: (preview['max_order_id'] as num?)?.toInt() ?? 0,
      password: _passwordController.text,
      mode: _mode,
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final count = (preview?['orders_count'] as num?)?.toInt() ?? 0;
    final canPurge = preview?['can_purge'] == true;
    final shiply = (preview?['shiply_parcels_count'] as num?)?.toInt() ?? 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_sweep_outlined, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('تنظيف الطلبيات التجريبية')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _mode == 'orders_only_reset'
                    ? 'سيتم حذف الطلبيات فقط وتصفير رقم الطلبية وID. لن يتغير المخزون أو الصناديق أو الديون.'
                    : 'سيتم حذف الطلبيات مع عكس صافي أثرها على المخزون والصناديق والديون.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _ModeOption(
                selected: _mode == 'orders_only_reset',
                title: const Text('حذف الطلبيات فقط + تصفير العدادات'),
                subtitle: const Text(
                  'لا يغيّر المخزون أو الصناديق أو الديون. استرجع النسخة قبل إنشاء طلبية جديدة.',
                ),
                onTap: _loading || _deleting
                    ? null
                    : () => _selectMode('orders_only_reset'),
              ),
              _ModeOption(
                selected: _mode == 'with_effects',
                title: const Text('حذف مع عكس الآثار'),
                subtitle: const Text('يعكس المخزون والصناديق والديون المرتبطة'),
                onTap: _loading || _deleting
                    ? null
                    : () => _selectMode('with_effects'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading || _deleting ? null : _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('حتى نهاية $_beforeText'),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (preview != null) ...[
                _PreviewCard(preview: preview, controller: widget.controller),
                if (shiply > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'تنبيه: يوجد $shiply طرد Shiply. التنظيف محلي ولا يحذف الطرود من سحابة Shiply.',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
                if (!canPurge && count > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _mode == 'orders_only_reset' &&
                            preview['can_reset_counters'] != true
                        ? 'تصفير العدادات يتطلب اختيار جميع الطلبيات الحالية.'
                        : 'التنظيف موقوف لوجود فواتير بيع أو مرتجعات مالية تحتاج معالجة منفصلة.',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmationController,
                  enabled: !_deleting && count > 0 && canPurge,
                  decoration: const InputDecoration(
                    labelText: 'اكتب DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  enabled: !_deleting && count > 0 && canPurge,
                  obscureText: true,
                  onSubmitted: (_) => _deleting ? null : _purge(),
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور الأدمن',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _deleting
              ? null
              : () async {
                  await SalesOrdersPurgeBackupsDialog.show(
                    context,
                    widget.controller,
                  );
                  if (mounted) await _loadPreview();
                },
          icon: const Icon(Icons.restore_outlined),
          label: const Text('نسخ الاسترجاع'),
        ),
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed:
              _loading || _deleting || count == 0 || !canPurge ? null : _purge,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(_deleting ? 'جاري التنظيف...' : 'حذف $count طلبية'),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: title,
      subtitle: subtitle,
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.controller});

  final Map<String, dynamic> preview;
  final SalesOrdersController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = Map<String, dynamic>.from(
      preview['status_counts'] as Map? ?? const {},
    );
    final cash = Map<String, dynamic>.from(
      preview['net_cash_by_currency'] as Map? ?? const {},
    );
    final lines = <String>[
      'الطلبيات: ${_number('orders_count')}',
      'المنتجات المرتبطة: ${_number('items_count')}',
      'التسويات: ${_number('settlements_count')}',
      'المرتجعات: ${_number('returns_count')}',
      'فواتير البيع المرتبطة: ${_number('linked_instant_sales_count')}',
      'الملفات: ${_number('media_count')}',
      if (statuses.isNotEmpty)
        'الحالات: ${statuses.entries.map((entry) => '${controller.statusLabel(entry.key)} ${entry.value}').join(' • ')}',
      if (cash.isNotEmpty && preview['mode'] == 'with_effects')
        'صافي المبالغ التي ستعكس: ${cash.entries.map((entry) => '${entry.value} ${entry.key}').join(' • ')}',
      if (preview['mode'] == 'orders_only_reset')
        'العدادات: ستبدأ الطلبية التالية من ID 1 ورقم 0000001',
      'نسخة الاسترجاع: تُحفظ تلقائياً قبل الحذف',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(lines.join('\n')),
    );
  }

  int _number(String key) => (preview[key] as num?)?.toInt() ?? 0;
}
