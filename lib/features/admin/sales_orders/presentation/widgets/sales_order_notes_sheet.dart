import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/media_permissions.dart';
import '../../data/models/sales_order_model.dart';

typedef SaveOrderNote = Future<SalesOrderDetailModel?> Function(
    String scope, String text, List<XFile> images);

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
  final images = <XFile>[];
  late SalesOrderDetailModel order;
  late String scope;
  bool saving = false;

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

  Future<void> _pick(bool camera) async {
    if (images.length >= 5 || saving) return;
    try {
      if (camera && !await ensureCameraPermission()) return;
      final picked = camera
          ? [await ImagePicker().pickImage(source: ImageSource.camera)]
              .whereType<XFile>()
              .toList()
          : await ImagePicker().pickMultiImage();
      if (mounted) {
        setState(() => images.addAll(picked.take(5 - images.length)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر اختيار الصورة')));
      }
    }
  }

  Future<void> _save() async {
    if (saving || (text.text.trim().isEmpty && images.isEmpty)) return;
    setState(() => saving = true);
    try {
      final updated =
          await widget.onSave(scope, text.text.trim(), List.of(images));
      if (mounted && updated != null) {
        setState(() {
          order = updated;
          text.clear();
          images.clear();
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _zoom(String url) => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
            child: Stack(children: [
              InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
              Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close))),
            ]),
          ));

  @override
  Widget build(BuildContext context) {
    final notes = order.noteLog.where((note) => note.scope == scope).toList();
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: const Color(0xFFF3F4F6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
              child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16, 18, 16, 18 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ملاحظات الطلبية ${order.serialNumber ?? order.id}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827))),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                        label: const Text('خارجية / تعليقات'),
                        selected: scope == 'external',
                        onSelected:
                            saving || text.text.isNotEmpty || images.isNotEmpty
                                ? null
                                : (_) => setState(() => scope = 'external')),
                    ChoiceChip(
                        label: const Text('داخلية'),
                        selected: scope == 'internal',
                        onSelected:
                            saving || text.text.isNotEmpty || images.isNotEmpty
                                ? null
                                : (_) => setState(() => scope = 'internal')),
                  ]),
                  const Text(
                      'ملاحظات الموظفين؛ لا تظهر في PDF إلا عند اختيار تضمينها.'),
                  if (scope == 'internal' &&
                      (order.notes ?? '').trim().isNotEmpty)
                    Card(
                        color: const Color(0xFFE5E7EB),
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(order.notes!,
                                style: const TextStyle(
                                    color: Color(0xFF111827))))),
                  for (final note in notes)
                    Card(
                        color: const Color(0xFFE5E7EB),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('${note.userName} • ${note.createdAt}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF374151))),
                                if (note.note.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text(note.note,
                                          style: const TextStyle(
                                              color: Color(0xFF111827)))),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final url in note.images)
                                    InkWell(
                                        onTap: () => _zoom(url),
                                        child: Image.network(url,
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                    width: 84,
                                                    height: 84,
                                                    child: Icon(Icons
                                                        .broken_image_outlined)))),
                                ]),
                              ]),
                        )),
                  const SizedBox(height: 12),
                  TextField(
                      controller: text,
                      enabled: !saving,
                      maxLines: 3,
                      maxLength: 2000,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'إضافة ملاحظة',
                          hintText: 'يمكن حفظ نص أو صور أو الاثنين',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFE5E7EB))),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < images.length; i++)
                      Stack(children: [
                        Image.file(File(images[i].path),
                            width: 84, height: 84, fit: BoxFit.cover),
                        Positioned(
                            left: 0,
                            top: 0,
                            child: IconButton(
                                onPressed: saving
                                    ? null
                                    : () => setState(() => images.removeAt(i)),
                                style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5E7EB)),
                                icon: const Icon(Icons.close,
                                    color: Color(0xFF111827))))
                      ]),
                  ]),
                  Wrap(spacing: 10, children: [
                    TextButton.icon(
                        onPressed: saving || images.length >= 5
                            ? null
                            : () => _pick(true),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('كاميرا')),
                    TextButton.icon(
                        onPressed: saving || images.length >= 5
                            ? null
                            : () => _pick(false),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('معرض الصور')),
                  ]),
                  Text('${images.length}/5 صور — حتى 8 MB للصورة'),
                  OutlinedButton.icon(
                      onPressed:
                          saving || (text.text.trim().isEmpty && images.isEmpty)
                              ? null
                              : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: const Text('حفظ الملاحظة والصور')),
                ]),
          )),
        ));
  }
}
