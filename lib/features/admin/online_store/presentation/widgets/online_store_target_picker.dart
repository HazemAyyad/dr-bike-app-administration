import 'package:flutter/material.dart';
import '../utils/online_store_admin_ui.dart';

class OnlineStoreTargetOption {
  const OnlineStoreTargetOption({
    required this.type,
    required this.id,
    required this.label,
    this.subtitle,
  });

  final String type;
  final int id;
  final String label;
  final String? subtitle;

  String get key => '$type:$id';
  Map<String, dynamic> toJson() => {
        'target_type': type,
        'target_id': id,
      };
}

Future<List<OnlineStoreTargetOption>?> showOnlineStoreTargetPicker(
  BuildContext context, {
  required String title,
  required List<OnlineStoreTargetOption> options,
  required Iterable<String> selectedKeys,
  bool multiple = true,
}) async {
  final selected = selectedKeys.toSet();
  var query = '';
  return showDialog<List<OnlineStoreTargetOption>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final visible = options
            .where((option) => '${option.label} ${option.subtitle ?? ''}'
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList(growable: false);
        return OnlineStoreDialog(
          icon: Icons.ads_click_outlined,
          title: Text(title),
          content: SizedBox(
            width: OnlineStoreAdminUi.dialogWidth(context),
            height: (MediaQuery.sizeOf(context).height * .65).clamp(280, 560),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, index) {
                          final option = visible[index];
                          return CheckboxListTile(
                            dense: true,
                            value: selected.contains(option.key),
                            title: Text(option.label),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(option.subtitle!),
                            onChanged: (value) => setState(() {
                              if (!multiple) selected.clear();
                              if (value == true) {
                                selected.add(option.key);
                              } else {
                                selected.remove(option.key);
                              }
                            }),
                          );
                        },
                      ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: () => Navigator.pop(
                dialogContext,
                options
                    .where((option) => selected.contains(option.key))
                    .toList(growable: false),
              ),
              child: const Text('اعتماد الاختيار'),
            ),
          ],
        );
      },
    ),
  );
}

List<String> onlineStoreTargetKeys(dynamic rows) =>
    (rows is List ? rows : const [])
        .whereType<Map>()
        .map((row) => '${row['target_type']}:${row['target_id']}')
        .toList(growable: false);
