import 'package:flutter/material.dart';

import '../utils/online_store_admin_ui.dart';

class OnlineStoreFormSection extends StatelessWidget {
  const OnlineStoreFormSection({
    Key? key,
    required this.title,
    required this.child,
    this.description,
    this.icon,
  }) : super(key: key);

  final String title;
  final String? description;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: OnlineStoreAdminUi.accent),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!,
                style: const TextStyle(
                    color: OnlineStoreAdminUi.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class OnlineStoreDateTimeField extends StatelessWidget {
  const OnlineStoreDateTimeField({
    Key? key,
    required this.controller,
    required this.label,
    this.includeTime = true,
    this.helpText,
  }) : super(key: key);

  final TextEditingController controller;
  final String label;
  final bool includeTime;
  final String? helpText;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: helpText,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: controller.text.isEmpty
              ? const Icon(Icons.chevron_left)
              : IconButton(
                  tooltip: 'مسح التاريخ',
                  onPressed: () {
                    controller.clear();
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
        onTap: () => _pick(context),
      );

  Future<void> _pick(BuildContext context) async {
    final parsed = DateTime.tryParse(controller.text);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: parsed ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: label,
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (date == null || !context.mounted) return;
    var result = date;
    if (includeTime) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            parsed == null ? TimeOfDay.now() : TimeOfDay.fromDateTime(parsed),
        helpText: 'اختيار الوقت',
        cancelText: 'إلغاء',
        confirmText: 'اختيار',
      );
      if (time == null) return;
      result =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    controller.text = includeTime
        ? result.toIso8601String().substring(0, 16).replaceFirst('T', ' ')
        : result.toIso8601String().substring(0, 10);
  }
}

class OnlineStoreReorderHint extends StatelessWidget {
  const OnlineStoreReorderHint({Key? key, this.compact = false})
      : super(key: key);
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: const Row(children: [
          Icon(Icons.drag_indicator, color: OnlineStoreAdminUi.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'الترتيب يحدد ما يظهر أولاً للعميل. اضغط مطولاً على علامة السحب ثم حرّك العنصر؛ الحفظ يتم تلقائياً.',
              style: TextStyle(color: OnlineStoreAdminUi.textSecondary),
            ),
          ),
        ]),
      );
}
