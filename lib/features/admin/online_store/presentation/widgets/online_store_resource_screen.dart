import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_resource_controller.dart';
import 'online_store_state_view.dart';
import '../utils/online_store_admin_ui.dart';

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

enum OnlineStoreResourceAction { activate, deactivate, delete }

typedef OnlineStoreResourceEditor = Future<Map<String, dynamic>?> Function(
  BuildContext context,
  OnlineStoreEntity? item,
);
typedef OnlineStoreResourceCardBuilder = Widget Function(
  BuildContext context,
  OnlineStoreEntity item,
  Widget trailing,
);

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
    this.actions = const {},
    this.onReorder,
    this.editor,
    this.cardBuilder,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final bool canManage;
  final String? subtitle;
  final List<OnlineStoreFormField> fields;
  final String? inspectLabel;
  final Future<void> Function(OnlineStoreEntity item)? onInspect;
  final Set<OnlineStoreResourceAction> actions;
  final Future<void> Function(List<int> ids)? onReorder;
  final OnlineStoreResourceEditor? editor;
  final OnlineStoreResourceCardBuilder? cardBuilder;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        floatingActionButton: canManage && (fields.isNotEmpty || editor != null)
            ? FloatingActionButton.extended(
                backgroundColor: OnlineStoreAdminUi.surface,
                foregroundColor: OnlineStoreAdminUi.textPrimary,
                shape: const StadiumBorder(
                  side: BorderSide(color: OnlineStoreAdminUi.accent),
                ),
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
                child: onReorder == null
                    ? ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: controller.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _resourceCard(context, controller.items[index]),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        buildDefaultDragHandles: false,
                        itemCount: controller.items.length,
                        onReorder: (oldIndex, newIndex) =>
                            controller.reorderItems(
                          oldIndex,
                          newIndex,
                          onReorder!,
                        ),
                        itemBuilder: (_, index) => Padding(
                          key: ValueKey(controller.items[index].id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _resourceCard(
                            context,
                            controller.items[index],
                            reorderIndex: index,
                          ),
                        ),
                      ),
              ),
            )),
      );

  Widget _resourceCard(
    BuildContext context,
    OnlineStoreEntity item, {
    int? reorderIndex,
  }) {
    final trailing = _trailing(item, reorderIndex);
    if (cardBuilder != null) return cardBuilder!(context, item, trailing);
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        onTap: canManage && (fields.isNotEmpty || editor != null)
            ? () => _showEditor(context, item: item)
            : null,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            border: Border.all(color: OnlineStoreAdminUi.border),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: OnlineStoreAdminUi.accent),
        ),
        title: Text(item.label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            subtitle ?? (item.status.isEmpty ? '#${item.id}' : item.status)),
        trailing: trailing,
      ),
    );
  }

  Widget _trailing(OnlineStoreEntity item, int? reorderIndex) {
    final hasMenu = canManage && (actions.isNotEmpty || inspectLabel != null);
    if (!hasMenu && reorderIndex == null) {
      return const Icon(Icons.chevron_left);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (reorderIndex != null && canManage)
        ReorderableDragStartListener(
          index: reorderIndex,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.drag_handle),
          ),
        ),
      if (hasMenu)
        PopupMenuButton<String>(
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
            if (actions.contains(OnlineStoreResourceAction.activate))
              const PopupMenuItem(value: 'activate', child: Text('تفعيل')),
            if (actions.contains(OnlineStoreResourceAction.deactivate))
              const PopupMenuItem(value: 'deactivate', child: Text('إيقاف')),
            if (actions.contains(OnlineStoreResourceAction.delete))
              const PopupMenuItem(value: 'delete', child: Text('حذف')),
            if (inspectLabel != null)
              PopupMenuItem(value: 'inspect', child: Text(inspectLabel!)),
          ],
        ),
    ]);
  }

  Future<void> _showEditor(BuildContext context,
      {OnlineStoreEntity? item}) async {
    if (editor != null) {
      final payload = await editor!(context, item);
      if (payload == null) return;
      if (item == null) {
        await controller.create(payload);
      } else {
        await controller.updateItem(item.id, payload);
      }
      return;
    }
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
          content: OnlineStoreDialogBody(
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
            OutlinedButton(
                style: OnlineStoreAdminUi.actionButtonStyle,
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
