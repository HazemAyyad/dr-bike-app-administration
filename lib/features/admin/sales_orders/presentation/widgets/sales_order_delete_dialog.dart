import 'package:flutter/material.dart';

class SalesOrderDeleteDialog extends StatefulWidget {
  const SalesOrderDeleteDialog(
      {Key? key,
      required this.preview,
      required this.force,
      required this.onDelete})
      : super(key: key);
  final Map<String, dynamic> preview;
  final bool force;
  final Future<bool> Function(String reason, String password) onDelete;

  @override
  State<SalesOrderDeleteDialog> createState() => _SalesOrderDeleteDialogState();
}

class _SalesOrderDeleteDialogState extends State<SalesOrderDeleteDialog> {
  final reason = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    reason.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        backgroundColor: const Color(0xFFF3F4F6),
        title: Text(
            '${widget.force ? 'حذف إجباري' : 'حذف الطلبية'} ${widget.preview['serial_number'] ?? ''}',
            style: const TextStyle(color: Color(0xFF111827))),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${widget.preview['message']}',
              style: const TextStyle(color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Text(
              'استخدامات كوبون: ${(widget.preview['related'] as Map?)?['online_store_coupon_redemptions'] ?? 0} — عروض: ${(widget.preview['related'] as Map?)?['online_store_promotion_redemptions'] ?? 0}'),
          Text(
              'فواتير مرتبطة: ${widget.preview['linked_invoices'] ?? 0} — مرتجعات مالية: ${widget.preview['financial_returns'] ?? 0}'),
          const SizedBox(height: 8),
          const Text('تحفظ نسخة استرجاع ضمن نسخ الطلبيات قبل تنفيذ الحذف.'),
          TextField(
              controller: reason,
              enabled: !busy,
              maxLength: 1000,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText:
                      widget.force ? 'سبب الحذف *' : 'سبب الحذف (اختياري)')),
          if (widget.force)
            TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration:
                    const InputDecoration(labelText: 'كلمة مرور الأدمن *')),
        ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          OutlinedButton(
              onPressed: busy ||
                      (widget.force &&
                          (reason.text.trim().isEmpty || password.text.isEmpty))
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final deleted = await widget.onDelete(
                            reason.text.trim(), password.text);
                        if (deleted && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(busy ? 'جارٍ الحذف…' : 'تأكيد الحذف',
                  style: const TextStyle(color: Color(0xFFB91C1C)))),
        ],
      ));
}
