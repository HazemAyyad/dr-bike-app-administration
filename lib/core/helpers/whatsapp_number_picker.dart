import 'package:flutter/material.dart';

import 'app_failure_notice.dart';
import 'whatsapp_launcher.dart';

Future<void> showWhatsAppNumberPicker(
  BuildContext context, {
  required String phone,
  String invalidMessage = 'رقم الهاتف غير صالح للتواصل عبر واتساب',
}) async {
  final candidates = WhatsAppLauncher.numberCandidates(phone);
  if (candidates.isEmpty) {
    AppFailureNotice.show(
      context: context,
      title: 'خطأ',
      message: invalidMessage,
    );
    return;
  }

  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'اختر مقدمة واتساب',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final candidate in candidates)
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text('واتساب +${candidate.substring(0, 3)}'),
              subtitle: Text('+$candidate'),
              onTap: () => Navigator.of(context).pop(candidate),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (selected == null) return;

  final opened = await WhatsAppLauncher.openChat(selected);
  if (!opened && context.mounted) {
    AppFailureNotice.show(
      context: context,
      title: 'خطأ',
      message: 'تعذر فتح واتساب على هذا الجهاز',
    );
  }
}
