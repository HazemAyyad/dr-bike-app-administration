import 'package:flutter/material.dart';

import '../../../whatsapp_center/presentation/utils/social_datetime_formatters.dart';
import '../../data/models/sales_order_model.dart';
import 'sales_order_note_media.dart';

typedef SaveOrderNote = Future<SalesOrderDetailModel?> Function(
    String scope, String text, List<WhatsAppCapture> media);

class SalesOrderNotesSheet extends StatefulWidget {
  const SalesOrderNotesSheet(
      {Key? key,
      required this.order,
      required this.initialScope,
      required this.onSave})
      : super(key: key);
  final SalesOrderDetailModel order;
  final String initialScope;
  final SaveOrderNote onSave;
  @override
  State<SalesOrderNotesSheet> createState() => _SalesOrderNotesSheetState();
}

class _SalesOrderNotesSheetState extends State<SalesOrderNotesSheet> {
  final text = TextEditingController();
  final media = <WhatsAppCapture>[];
  final drafts = <String, String>{};
  final draftMedia = <String, List<WhatsAppCapture>>{};
  late SalesOrderDetailModel order;
  late String scope;
  bool saving = false;
  bool picking = false;
  bool get busy => saving || picking;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    scope = widget.initialScope;
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void _switchScope(String value) {
    if (busy || scope == value) return;
    setState(() {
      drafts[scope] = text.text;
      draftMedia[scope] = List.of(media);
      scope = value;
      text.text = drafts[scope] ?? '';
      media
        ..clear()
        ..addAll(draftMedia[scope] ?? []);
    });
  }

  Future<void> _pick(bool camera) async {
    if (media.length >= 5 || busy) return;
    setState(() => picking = true);
    try {
      final picked = await pickSalesOrderNoteMedia(
          camera: camera, remaining: 5 - media.length);
      if (mounted) setState(() => media.addAll(picked));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر اختيار المرفقات')));
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _save() async {
    if (busy || (text.text.trim().isEmpty && media.isEmpty)) return;
    setState(() => saving = true);
    try {
      final updated =
          await widget.onSave(scope, text.text.trim(), List.of(media));
      if (mounted && updated != null) {
        setState(() {
          order = updated;
          text.clear();
          media.clear();
          drafts.remove(scope);
          draftMedia.remove(scope);
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes =
        order.noteLog.where((note) => note.scope == scope).toList().reversed;
    final legacyNote =
        scope == 'internal' && (order.notes ?? '').trim().isNotEmpty;
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: const Color(0xFFF3F4F6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
              child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .92),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, 18 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.sticky_note_2_outlined,
                          color: Color(0xFF635CB1)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'ملاحظات الطلبية ${order.serialNumber ?? order.id}',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800))),
                      IconButton(
                          tooltip: 'إغلاق',
                          onPressed: busy ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 22)),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _scopeChip('internal', 'داخلية', order.internalNotesCount,
                          Icons.lock_outline),
                      _scopeChip('external', 'خارجية', order.externalNotesCount,
                          Icons.comment_outlined),
                    ]),
                    const SizedBox(height: 10),
                    const Text(
                        'ملاحظات الموظفين؛ تُضمّن في PDF عند اختيارها فقط.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEAECF0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE1E7))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  scope == 'internal'
                                      ? 'إضافة ملاحظة داخلية'
                                      : 'إضافة ملاحظة خارجية',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              TextField(
                                  controller: text,
                                  enabled: !busy,
                                  minLines: 2,
                                  maxLines: 4,
                                  maxLength: 2000,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                      hintText:
                                          'اكتب الملاحظة أو أرفق صورة أو فيديو…',
                                      hintStyle: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280)),
                                      filled: true,
                                      fillColor: const Color(0xFFF3F4F6),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none))),
                              if (media.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (var i = 0; i < media.length; i++)
                                            SalesOrderNoteMediaTile(
                                                path: media[i].path,
                                                local: true,
                                                isVideo: media[i].mediaKind ==
                                                    'video',
                                                onRemove: busy
                                                    ? null
                                                    : () => setState(() =>
                                                        media.removeAt(i))),
                                        ])),
                              Wrap(spacing: 8, children: [
                                TextButton.icon(
                                    onPressed: busy || media.length >= 5
                                        ? null
                                        : () => _pick(true),
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        size: 20),
                                    label: const Text('كاميرا / فيديو')),
                                TextButton.icon(
                                    onPressed: busy || media.length >= 5
                                        ? null
                                        : () => _pick(false),
                                    icon: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 20),
                                    label: const Text('المعرض')),
                              ]),
                              Text(
                                  '${media.length}/5 مرفقات • الصورة 8 MB، الفيديو 50 MB',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF6B7280))),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      foregroundColor: const Color(0xFF111827),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      side: const BorderSide(
                                          color: Color(0xFFB9B5D6)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  onPressed: busy ||
                                          (text.text.trim().isEmpty &&
                                              media.isEmpty)
                                      ? null
                                      : _save,
                                  icon: saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.check_rounded,
                                          color: Color(0xFF635CB1)),
                                  label: Text(saving
                                      ? 'جارٍ حفظ الملاحظة…'
                                      : 'حفظ الملاحظة')),
                            ])),
                    const SizedBox(height: 20),
                    const Text('سجل الملاحظات',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    if (notes.isEmpty && !legacyNote)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('لا توجد ملاحظات في هذا القسم بعد',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7280)))),
                    for (final note in notes) _NoteCard(note: note),
                    if (legacyNote)
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('ملاحظة محفوظة مع بيانات الطلبية',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                Text(order.notes!),
                              ])),
                  ]),
            ),
          )),
        ));
  }

  Widget _scopeChip(
          String value, String label, int count, IconData icon) =>
      ChoiceChip(
          avatar: Icon(
              icon,
              size: 17,
              color: scope == value
                  ? const Color(0xFF635CB1)
                  : const Color(0xFF6B7280)),
          label: Text('$label ($count)'),
          selected: scope == value,
          showCheckmark: false,
          selectedColor: const Color(0xFFE5E7EB),
          backgroundColor: const Color(0xFFF3F4F6),
          labelStyle: const TextStyle(
              color: Color(0xFF111827), fontWeight: FontWeight.w700),
          onSelected: busy ? null : (_) => _switchScope(value));
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final SalesOrderNoteModel note;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(note.createdAt)?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE1E7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFE0E2E7),
              child: Icon(Icons.person_outline,
                  size: 18, color: Color(0xFF635CB1))),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note.userName,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 6, children: [
          _stamp(
              Icons.calendar_today_outlined,
              date == null
                  ? 'تاريخ غير متوفر'
                  : '${date.day}/${date.month}/${date.year}'),
          if (date != null)
            _stamp(Icons.schedule_rounded, formatSocialClock(date)),
        ]),
        if (note.note.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(note.note, style: const TextStyle(height: 1.6))),
        if (note.media.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final file in note.media)
                  SalesOrderNoteMediaTile(
                      path: file.url, isVideo: file.isVideo),
              ])),
      ]),
    );
  }

  Widget _stamp(IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ]);
}
