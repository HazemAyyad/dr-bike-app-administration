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

String onlineStoreFriendlyDate(Object? value, {bool includeTime = true}) {
  final raw = '${value ?? ''}'.trim();
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return raw.isEmpty ? 'غير محدد' : raw;
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];
  final day = '${date.day} ${months[date.month - 1]} ${date.year}';
  if (!includeTime) return day;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day، $hour:$minute ${date.hour < 12 ? 'ص' : 'م'}';
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
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helpText,
              isDense: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              prefixIcon: const Icon(Icons.event_outlined, size: 20),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: value.text.isEmpty
                  ? const Icon(Icons.chevron_left)
                  : IconButton(
                      tooltip: 'مسح التاريخ',
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close),
                    ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            child: Text(
              value.text.isEmpty
                  ? 'اضغط لاختيار التاريخ${includeTime ? ' والوقت' : ''}'
                  : onlineStoreFriendlyDate(value.text,
                      includeTime: includeTime),
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                color: value.text.isEmpty
                    ? OnlineStoreAdminUi.textSecondary
                    : OnlineStoreAdminUi.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: OnlineStoreAdminUi.accent,
                surface: OnlineStoreAdminUi.modalSurface,
                onSurface: OnlineStoreAdminUi.textPrimary,
              ),
        ),
        child: child!,
      ),
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
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: OnlineStoreAdminUi.accent,
                  surface: OnlineStoreAdminUi.modalSurface,
                  onSurface: OnlineStoreAdminUi.textPrimary,
                ),
          ),
          child: child!,
        ),
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

class OnlineStoreDateRangeFields extends StatelessWidget {
  const OnlineStoreDateRangeFields({
    Key? key,
    required this.fromController,
    required this.toController,
    this.fromLabel = 'من تاريخ',
    this.toLabel = 'إلى تاريخ',
    this.includeTime = false,
  }) : super(key: key);

  final TextEditingController fromController;
  final TextEditingController toController;
  final String fromLabel;
  final String toLabel;
  final bool includeTime;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final from = OnlineStoreDateTimeField(
            controller: fromController,
            label: fromLabel,
            includeTime: includeTime,
          );
          final to = OnlineStoreDateTimeField(
            controller: toController,
            label: toLabel,
            includeTime: includeTime,
          );
          if (constraints.maxWidth < 480) {
            return Column(children: [
              from,
              const SizedBox(height: 10),
              to,
            ]);
          }
          return Row(children: [
            Expanded(child: from),
            const SizedBox(width: 10),
            Expanded(child: to),
          ]);
        },
      );
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
