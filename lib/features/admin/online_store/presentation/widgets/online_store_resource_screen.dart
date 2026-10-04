import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_resource_controller.dart';
import 'online_store_state_view.dart';

class OnlineStoreFormField {
  const OnlineStoreFormField(
    this.keyName,
    this.label, {
    this.options = const [],
    this.numeric = false,
    this.boolean = false,
    this.json = false,
  });
  final String keyName;
  final String label;
  final List<String> options;
  final bool numeric;
  final bool boolean;
  final bool json;
}

class OnlineStoreResourceScreen<T extends OnlineStoreResourceController>
    extends GetView<T> {
  const OnlineStoreResourceScreen({
    Key? key,
    required this.title,
    required this.icon,
    this.canManage = false,
    this.subtitle,
    this.fields = const [],
    this.inspectLabel,
    this.onInspect,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final bool canManage;
  final String? subtitle;
  final List<OnlineStoreFormField> fields;
  final String? inspectLabel;
  final Future<void> Function(OnlineStoreEntity item)? onInspect;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        floatingActionButton: canManage && fields.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              )
            : null,
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.items.isEmpty,
              onRetry: controller.load,
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = controller.items[index];
                    return Card(
                      color: const Color(0xFFF7F7FA),
                      child: ListTile(
                        onTap: canManage && fields.isNotEmpty
                            ? () => _showEditor(context, item: item)
                            : null,
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF6F42C1).withValues(alpha: .1),
                          child: Icon(icon, color: const Color(0xFF6F42C1)),
                        ),
                        title: Text(item.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(subtitle ??
                            (item.status.isEmpty
                                ? '#${item.id}'
                                : item.status)),
                        trailing: canManage
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    controller.remove(item.id);
                                  }
                                  if (value == 'activate') {
                                    controller.action(item.id, 'activate');
                                  }
                                  if (value == 'deactivate') {
                                    controller.action(item.id, 'deactivate');
                                  }
                                  if (value == 'inspect') {
                                    onInspect?.call(item);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'activate', child: Text('تفعيل')),
                                  const PopupMenuItem(
                                      value: 'deactivate',
                                      child: Text('إيقاف')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('حذف')),
                                  if (inspectLabel != null)
                                    PopupMenuItem(
                                        value: 'inspect',
                                        child: Text(inspectLabel!)),
                                ],
                              )
                            : const Icon(Icons.chevron_left),
                      ),
                    );
                  },
                ),
              ),
            )),
      );

  Future<void> _showEditor(BuildContext context,
      {OnlineStoreEntity? item}) async {
    final controllers = <String, TextEditingController>{};
    final booleans = <String, bool>{};
    for (final field in fields) {
      final value = item == null ? null : _read(item.values, field.keyName);
      if (field.boolean) {
        booleans[field.keyName] = value == true || value == 1;
      } else {
        final initial = value == null || '$value'.isEmpty
            ? (field.options.isEmpty ? '' : field.options.first)
            : value;
        controllers[field.keyName] = TextEditingController(
            text: field.json && value != null ? jsonEncode(value) : '$initial');
      }
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'إضافة $title' : 'تعديل ${item.label}'),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields.map((field) {
                  if (field.boolean) {
                    return SwitchListTile(
                      title: Text(field.label),
                      value: booleans[field.keyName] ?? false,
                      onChanged: (value) =>
                          setState(() => booleans[field.keyName] = value),
                    );
                  }
                  if (field.options.isNotEmpty) {
                    final current = controllers[field.keyName]!.text;
                    return DropdownButtonFormField<String>(
                      initialValue: field.options.contains(current)
                          ? current
                          : field.options.first,
                      decoration: InputDecoration(labelText: field.label),
                      items: field.options
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) =>
                          controllers[field.keyName]!.text = value ?? '',
                    );
                  }
                  return TextField(
                    controller: controllers[field.keyName],
                    keyboardType: field.numeric ? TextInputType.number : null,
                    decoration: InputDecoration(labelText: field.label),
                  );
                }).toList()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (accepted == true) {
      final payload = <String, dynamic>{};
      for (final field in fields) {
        dynamic value = field.boolean
            ? booleans[field.keyName]
            : controllers[field.keyName]!.text.trim();
        if (field.numeric && '$value'.isNotEmpty) {
          value = num.tryParse('$value');
        }
        if (field.json && '$value'.trim().isNotEmpty) {
          value = jsonDecode('$value');
        } else if (field.json) {
          value = null;
        }
        _write(payload, field.keyName, value);
      }
      if (item == null) {
        await controller.create(payload);
      } else {
        await controller.updateItem(item.id, payload);
      }
    }
    for (final value in controllers.values) {
      value.dispose();
    }
  }

  dynamic _read(Map<String, dynamic> values, String key) {
    final parts = key.split('.');
    dynamic current = values;
    for (final part in parts) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  void _write(Map<String, dynamic> target, String key, dynamic value) {
    final parts = key.split('.');
    var current = target;
    for (var i = 0; i < parts.length - 1; i++) {
      current = current.putIfAbsent(parts[i], () => <String, dynamic>{})
          as Map<String, dynamic>;
    }
    current[parts.last] = value;
  }
}
