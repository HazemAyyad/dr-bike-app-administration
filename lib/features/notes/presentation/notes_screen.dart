import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_colors.dart';
import '../data/notes_service.dart';

class NotesScreen extends StatefulWidget {
  final int? noteId;

  const NotesScreen({Key? key, this.noteId}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final service = NotesService();
  final searchController = TextEditingController();
  final titleController = TextEditingController();
  final blocks = <_NoteBlock>[];
  final collaborators = <NoteCollaborator>[];
  final colors = const ['', '#fff7cc', '#e6f7ef', '#e9f0ff', '#ffe8e8'];

  bool loading = true;
  bool saving = false;
  String scope = 'active';
  String visibility = 'private';
  String color = '';
  bool isPinned = false;
  bool isArchived = false;
  NoteItem? currentNote;
  List<NoteItem> notes = [];

  bool get inEditor => widget.noteId != null || currentNote != null;
  int? get editingId {
    final id = widget.noteId ?? currentNote?.id;
    return id != null && id > 0 ? id : null;
  }

  @override
  void initState() {
    super.initState();
    widget.noteId == null ? _loadList() : _loadNote(widget.noteId!);
  }

  @override
  void dispose() {
    searchController.dispose();
    titleController.dispose();
    for (final block in blocks) {
      block.dispose();
    }
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() => loading = true);
    try {
      notes =
          await service.getNotes(scope: scope, search: searchController.text);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadNote(int id) async {
    setState(() => loading = true);
    try {
      final note = await service.getNote(id);
      _fillEditor(note);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _fillEditor(NoteItem note) {
    currentNote = note;
    titleController.text = note.title;
    visibility = note.visibility;
    color = note.color;
    isPinned = note.isPinned;
    isArchived = note.isArchived;
    collaborators
      ..clear()
      ..addAll(note.collaborators);
    for (final block in blocks) {
      block.dispose();
    }
    blocks
      ..clear()
      ..addAll(note.bodyJson.map((json) => _NoteBlock.fromJson(json)));
    if (blocks.isEmpty) blocks.add(_NoteBlock.text());
  }

  Future<void> _save() async {
    final hasContent = titleController.text.trim().isNotEmpty ||
        blocks.any((b) => b.hasContent);
    if (!hasContent) {
      _message('اكتب عنوان أو محتوى للملاحظة');
      return;
    }

    setState(() => saving = true);
    try {
      final note = await service.saveNote(
        id: editingId,
        title: titleController.text.trim(),
        bodyJson: blocks.map((e) => e.toJson()).toList(),
        visibility: visibility,
        color: color,
        isPinned: isPinned,
        isArchived: isArchived,
        collaborators: collaborators,
      );
      _fillEditor(note);
      _message('تم حفظ الملاحظة');
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<int?> _ensureSaved() async {
    if (editingId != null) return editingId;
    setState(() => saving = true);
    try {
      final note = await service.saveNote(
        title: titleController.text.trim(),
        bodyJson: blocks
            .where((block) => block.hasContent)
            .map((e) => e.toJson())
            .toList(),
        visibility: visibility,
        color: color,
        isPinned: isPinned,
        isArchived: isArchived,
        collaborators: collaborators,
      );
      _fillEditor(note);
      return note.id;
    } catch (e) {
      _message(e.toString());
      return null;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pickAttachment() async {
    final noteId = await _ensureSaved();
    if (noteId == null) return;
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = result?.files.first.path;
    if (path == null || path.isEmpty) return;
    setState(() => saving = true);
    try {
      final attachment = await service.uploadAttachment(noteId, path);
      setState(() => blocks.add(_NoteBlock.attachment(attachment)));
      await _save();
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addDrawing() async {
    final noteId = await _ensureSaved();
    if (noteId == null) return;
    final path = await Get.to<String>(() => const _DrawingScreen());
    if (path == null || path.isEmpty) return;
    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, path, type: 'drawing');
      setState(
          () => blocks.add(_NoteBlock.attachment(attachment, drawing: true)));
      await _save();
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _shareDialog() async {
    final users = await service.users();
    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: 0.82.sh),
          padding: EdgeInsets.all(16.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مشاركة الملاحظة',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: visibility,
                decoration: const InputDecoration(labelText: 'الظهور'),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('خاصة')),
                  DropdownMenuItem(value: 'shared', child: Text('مشاركة')),
                  DropdownMenuItem(value: 'public', child: Text('عامة للكل')),
                ],
                onChanged: (v) =>
                    setSheetState(() => visibility = v ?? 'private'),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, index) {
                    final user = users[index];
                    final selected = collaborators
                        .firstWhereOrNull((c) => c.userId == user.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(user.name),
                      subtitle: Text(
                          user.jobTitle.isEmpty ? user.type : user.jobTitle),
                      trailing: selected == null
                          ? TextButton(
                              onPressed: () => setSheetState(() {
                                collaborators.add(NoteCollaborator(
                                  userId: user.id,
                                  permission: 'view',
                                  user: user,
                                ));
                                visibility = 'shared';
                              }),
                              child: const Text('إضافة'),
                            )
                          : DropdownButton<String>(
                              value: selected.permission,
                              items: const [
                                DropdownMenuItem(
                                    value: 'view', child: Text('مشاهدة')),
                                DropdownMenuItem(
                                    value: 'edit', child: Text('تعديل')),
                                DropdownMenuItem(
                                    value: 'remove', child: Text('حذف')),
                              ],
                              onChanged: (value) => setSheetState(() {
                                collaborators
                                    .removeWhere((c) => c.userId == user.id);
                                if (value == 'view' || value == 'edit') {
                                  collaborators.add(NoteCollaborator(
                                    userId: user.id,
                                    permission: value!,
                                    user: user,
                                  ));
                                }
                              }),
                            ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Get.back();
                },
                child: const Text('تم'),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return inEditor ? _editorScaffold() : _listScaffold();
  }

  Widget _listScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: const Text('الملاحظات'),
        actions: [
          IconButton(
              onPressed: _loadList, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          currentNote = const NoteItem(
            id: 0,
            title: '',
            plainText: '',
            color: '',
            visibility: 'private',
            myPermission: 'owner',
            isPinned: false,
            isArchived: false,
            canEdit: true,
            canManageSharing: true,
            attachmentsCount: 0,
            owner: null,
            bodyJson: [],
            attachments: [],
            collaborators: [],
            updatedAt: null,
          );
          _fillEditor(currentNote!);
        }),
        child: const Icon(Icons.add_rounded),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadList,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث في الملاحظات',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        onPressed: _loadList,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _loadList(),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    children: [
                      _scopeChip('active', 'النشطة'),
                      _scopeChip('mine', 'ملاحظاتي'),
                      _scopeChip('shared', 'مشاركة معي'),
                      _scopeChip('public', 'عامة'),
                      _scopeChip('archived', 'الأرشيف'),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (notes.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 80.h),
                      child: const Center(child: Text('لا توجد ملاحظات')),
                    )
                  else
                    ...notes.map(_noteCard),
                ],
              ),
            ),
    );
  }

  Widget _scopeChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: scope == value,
      onSelected: (_) {
        setState(() => scope = value);
        _loadList();
      },
    );
  }

  Widget _noteCard(NoteItem note) {
    return Card(
      color: _noteColor(note.color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _loadNote(note.id),
        title: Text(note.title.isEmpty ? 'بدون عنوان' : note.title),
        subtitle: Text(
          note.plainText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Icon(note.isPinned ? Icons.push_pin : Icons.sticky_note_2),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (note.attachmentsCount > 0)
              Text('${note.attachmentsCount} مرفق',
                  style: TextStyle(fontSize: 11.sp)),
            Text(note.visibility == 'public' ? 'عامة' : note.myPermission),
          ],
        ),
      ),
    );
  }

  Widget _editorScaffold() {
    final canEdit = currentNote?.canEdit ?? true;
    return Scaffold(
      backgroundColor: _noteColor(color),
      appBar: AppBar(
        title: const Text('تحرير ملاحظة'),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            onPressed: canEdit ? _shareDialog : null,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            tooltip: 'حفظ',
            onPressed: saving || !canEdit ? null : _save,
            icon: saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                TextField(
                  controller: titleController,
                  enabled: canEdit,
                  style:
                      TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    hintText: 'العنوان',
                    border: InputBorder.none,
                  ),
                ),
                Wrap(
                  spacing: 8.w,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      selected: isPinned,
                      label: const Text('مثبتة'),
                      onSelected:
                          canEdit ? (v) => setState(() => isPinned = v) : null,
                    ),
                    FilterChip(
                      selected: isArchived,
                      label: const Text('أرشيف'),
                      onSelected: canEdit
                          ? (v) => setState(() => isArchived = v)
                          : null,
                    ),
                    ...colors.map(
                      (c) => InkWell(
                        onTap: canEdit ? () => setState(() => color = c) : null,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: _noteColor(c),
                          child: color == c
                              ? const Icon(Icons.check, size: 16)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ...blocks.asMap().entries.map(
                      (entry) => _blockWidget(entry.key, entry.value, canEdit),
                    ),
                if (canEdit)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Wrap(
                      spacing: 8.w,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => blocks.add(_NoteBlock.text())),
                          icon: const Icon(Icons.notes_rounded),
                          label: const Text('نص'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(
                              () => blocks.add(_NoteBlock.checklist())),
                          icon: const Icon(Icons.check_box_outlined),
                          label: const Text('Checklist'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickAttachment,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text('مرفق'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addDrawing,
                          icon: const Icon(Icons.draw_rounded),
                          label: const Text('رسم'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _blockWidget(int index, _NoteBlock block, bool canEdit) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_blockIcon(block.type), color: AppColors.primaryColor),
                SizedBox(width: 6.w),
                Expanded(child: Text(_blockLabel(block.type))),
                if (canEdit)
                  IconButton(
                    onPressed: () => setState(() {
                      blocks.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            if (block.type == 'text')
              TextField(
                controller: block.textController,
                enabled: canEdit,
                minLines: 2,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'اكتب هنا...',
                  border: InputBorder.none,
                ),
              )
            else if (block.type == 'checklist')
              ...block.checkItems.asMap().entries.map((entry) {
                final item = entry.value;
                return Row(
                  children: [
                    Checkbox(
                      value: item.checked,
                      onChanged: canEdit
                          ? (v) => setState(() => item.checked = v ?? false)
                          : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: item.controller,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          hintText: 'عنصر',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: () => setState(() {
                          block.checkItems.removeAt(entry.key).dispose();
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                );
              }),
            if (block.type == 'checklist' && canEdit)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => block.checkItems.add(_CheckItem())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة عنصر'),
                ),
              )
            else if (block.type == 'attachment' || block.type == 'drawing')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(block.type == 'drawing'
                    ? Icons.draw_rounded
                    : Icons.insert_drive_file_rounded),
                title: Text(block.attachmentName),
                subtitle: Text(block.attachmentUrl),
                onTap: block.attachmentUrl.isEmpty
                    ? null
                    : () => launchUrl(Uri.parse(block.attachmentUrl)),
              ),
          ],
        ),
      ),
    );
  }

  IconData _blockIcon(String type) {
    switch (type) {
      case 'checklist':
        return Icons.check_box_outlined;
      case 'drawing':
        return Icons.draw_rounded;
      case 'attachment':
        return Icons.attach_file_rounded;
      default:
        return Icons.notes_rounded;
    }
  }

  String _blockLabel(String type) {
    switch (type) {
      case 'checklist':
        return 'قائمة داخل الملاحظة';
      case 'drawing':
        return 'رسم';
      case 'attachment':
        return 'مرفق';
      default:
        return 'نص';
    }
  }

  Color _noteColor(String value) {
    switch (value) {
      case '#fff7cc':
        return const Color(0xfffff7cc);
      case '#e6f7ef':
        return const Color(0xffe6f7ef);
      case '#e9f0ff':
        return const Color(0xffe9f0ff);
      case '#ffe8e8':
        return const Color(0xffffe8e8);
      default:
        return Colors.white;
    }
  }

  void _message(String text) {
    Get.snackbar('الملاحظات', text, snackPosition: SnackPosition.BOTTOM);
  }
}

class _NoteBlock {
  final String type;
  final TextEditingController textController;
  final List<_CheckItem> checkItems;
  final int attachmentId;
  final String attachmentUrl;
  final String attachmentName;

  _NoteBlock({
    required this.type,
    TextEditingController? textController,
    List<_CheckItem>? checkItems,
    this.attachmentId = 0,
    this.attachmentUrl = '',
    this.attachmentName = '',
  })  : textController = textController ?? TextEditingController(),
        checkItems = checkItems ?? [];

  factory _NoteBlock.text([String text = '']) => _NoteBlock(
        type: 'text',
        textController: TextEditingController(text: text),
      );

  factory _NoteBlock.checklist([List<_CheckItem>? items]) => _NoteBlock(
        type: 'checklist',
        checkItems: items ?? [_CheckItem()],
      );

  factory _NoteBlock.attachment(NoteAttachment attachment,
          {bool drawing = false}) =>
      _NoteBlock(
        type:
            drawing || attachment.type == 'drawing' ? 'drawing' : 'attachment',
        attachmentId: attachment.id,
        attachmentUrl: attachment.url,
        attachmentName: attachment.originalName.isEmpty
            ? attachment.type
            : attachment.originalName,
      );

  factory _NoteBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'text';
    if (type == 'checklist') {
      final items = (json['items'] is List ? json['items'] as List : const [])
          .whereType<Map>()
          .map((e) => _CheckItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return _NoteBlock.checklist(items.isEmpty ? [_CheckItem()] : items);
    }
    if (type == 'attachment' || type == 'drawing') {
      return _NoteBlock(
        type: type,
        attachmentId:
            int.tryParse(json['attachment_id']?.toString() ?? '') ?? 0,
        attachmentUrl: json['url']?.toString() ?? '',
        attachmentName: json['name']?.toString() ?? type,
      );
    }
    return _NoteBlock.text(json['text']?.toString() ?? '');
  }

  bool get hasContent =>
      textController.text.trim().isNotEmpty ||
      checkItems.any((e) => e.controller.text.trim().isNotEmpty) ||
      attachmentId > 0;

  Map<String, dynamic> toJson() {
    if (type == 'checklist') {
      return {
        'type': 'checklist',
        'items': checkItems
            .map((e) => {
                  'text': e.controller.text.trim(),
                  'checked': e.checked,
                })
            .where((e) => (e['text'] as String).isNotEmpty)
            .toList(),
      };
    }
    if (type == 'attachment' || type == 'drawing') {
      return {
        'type': type,
        'attachment_id': attachmentId,
        'url': attachmentUrl,
        'name': attachmentName,
      };
    }
    return {'type': 'text', 'text': textController.text};
  }

  void dispose() {
    textController.dispose();
    for (final item in checkItems) {
      item.dispose();
    }
  }
}

class _CheckItem {
  final TextEditingController controller;
  bool checked;

  _CheckItem({String text = '', this.checked = false})
      : controller = TextEditingController(text: text);

  factory _CheckItem.fromJson(Map<String, dynamic> json) => _CheckItem(
        text: json['text']?.toString() ?? '',
        checked: json['checked'] == true,
      );

  void dispose() => controller.dispose();
}

class _DrawingScreen extends StatefulWidget {
  const _DrawingScreen();

  @override
  State<_DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<_DrawingScreen> {
  final key = GlobalKey();
  final points = <Offset?>[];
  Color color = Colors.black;
  double strokeWidth = 4;

  Future<void> _save() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/note_drawing_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    Get.back(result: file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رسم'),
        actions: [
          IconButton(
              onPressed: () => setState(points.clear),
              icon: const Icon(Icons.delete_outline)),
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                for (final c in [
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: InkWell(
                      onTap: () => setState(() => color = c),
                      child: CircleAvatar(backgroundColor: c, radius: 14),
                    ),
                  ),
                Expanded(
                  child: Slider(
                    value: strokeWidth,
                    min: 1,
                    max: 14,
                    onChanged: (v) => setState(() => strokeWidth = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: key,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final box =
                      key.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  setState(() =>
                      points.add(box.globalToLocal(details.globalPosition)));
                },
                onPanEnd: (_) => setState(() => points.add(null)),
                child: CustomPaint(
                  painter: _DrawingPainter(points, color, strokeWidth),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  const _DrawingPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
