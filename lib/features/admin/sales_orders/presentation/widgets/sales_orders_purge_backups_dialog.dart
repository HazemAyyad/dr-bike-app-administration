import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/sales_orders_controller.dart';

class SalesOrdersPurgeBackupsDialog extends StatefulWidget {
  const SalesOrdersPurgeBackupsDialog({
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
      builder: (_) => SalesOrdersPurgeBackupsDialog(controller: controller),
    );
  }

  @override
  State<SalesOrdersPurgeBackupsDialog> createState() =>
      _SalesOrdersPurgeBackupsDialogState();
}

class _SalesOrdersPurgeBackupsDialogState
    extends State<SalesOrdersPurgeBackupsDialog> {
  List<Map<String, dynamic>> _backups = const [];
  bool _loading = true;
  int? _restoringId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await widget.controller.loadPurgeBackups();
    if (!mounted) return;
    setState(() {
      _backups = rows ?? const [];
      _loading = false;
    });
  }

  Future<void> _restore(Map<String, dynamic> backup) async {
    final backupId = (backup['id'] as num?)?.toInt();
    if (backupId == null) return;
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استرجاع نسخة الطلبيات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم استرجاع ${backup['orders_count'] ?? 0} طلبية من النسخة #$backupId.',
            ),
            if (backup['mode'] == 'orders_only_reset') ...[
              const SizedBox(height: 8),
              const Text(
                'يجب ألا تكون أرقام الطلبيات القديمة قد استُخدمت لطلبيات جديدة.',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: confirmation,
              decoration: const InputDecoration(
                labelText: 'اكتب RESTORE',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة مرور الأدمن',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (confirmation.text.trim() != 'RESTORE' ||
                  password.text.isEmpty) {
                Get.snackbar('تنبيه', 'اكتب RESTORE وأدخل كلمة مرور الأدمن');
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) {
      password.dispose();
      confirmation.dispose();
      return;
    }

    setState(() => _restoringId = backupId);
    final restored = await widget.controller.restorePurgeBackup(
      backupId: backupId,
      password: password.text,
    );
    password.dispose();
    confirmation.dispose();
    if (!mounted) return;
    setState(() => _restoringId = null);
    if (restored) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_outlined),
          SizedBox(width: 8),
          Text('نسخ استرجاع الطلبيات'),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 430,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _backups.isEmpty
                ? const Center(child: Text('لا توجد نسخ استرجاع حتى الآن'))
                : ListView.separated(
                    itemCount: _backups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final backup = _backups[index];
                      final id = (backup['id'] as num?)?.toInt() ?? 0;
                      final available = backup['status'] == 'available';
                      final mode = backup['mode'] == 'orders_only_reset'
                          ? 'طلبيات فقط + تصفير العدادات'
                          : 'حذف مع عكس الآثار';
                      return ListTile(
                        leading: Icon(
                          available ? Icons.inventory_2_outlined : Icons.check,
                          color: available ? Colors.orange : Colors.green,
                        ),
                        title: Text(
                          'نسخة #$id — ${backup['orders_count'] ?? 0} طلبية',
                        ),
                        subtitle: Text(
                          '$mode\n${_date(backup['created_at'])}',
                        ),
                        isThreeLine: true,
                        trailing: available
                            ? TextButton.icon(
                                onPressed: _restoringId == null
                                    ? () => _restore(backup)
                                    : null,
                                icon: _restoringId == id
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.restore),
                                label: const Text('استرجاع'),
                              )
                            : const Text(
                                'تم الاسترجاع',
                                style: TextStyle(color: Colors.green),
                              ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
  }
}
