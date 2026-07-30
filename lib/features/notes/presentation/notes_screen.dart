import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/helpers/show_net_image.dart';
import '../../../core/services/initial_bindings.dart';
import '../../../routes/app_routes.dart';
import '../../admin/whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import '../../bottom_nav_bar/controllers/bottom_nav_bar_controller.dart';
import '../data/notes_service.dart';

class NotesScreen extends StatefulWidget {
  final int? noteId;

  const NotesScreen({Key? key, this.noteId}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const keepBackground = Color(0xffffefe4);
  static const keepSheet = Color(0xfffffbf7);
  static const keepInk = Color(0xff2f2925);
  static const keepMuted = Color(0xff8c817a);

  final service = NotesService();
  final searchController = TextEditingController();
  final titleController = TextEditingController();
  final blocks = <_NoteBlock>[];
  final collaborators = <NoteCollaborator>[];
  final colors = const ['', '#fff7cc', '#e6f7ef', '#e9f0ff', '#ffe8e8'];
  late final RecorderController recorder;

  bool loading = true;
  bool saving = false;
  bool gridView = true;
  bool addMenuOpen = false;
  bool recording = false;
  bool recordingPaused = false;
  String scope = 'active';
  String visibility = 'private';
  String color = '';
  List<String> labels = [];
  bool isPinned = false;
  bool isArchived = false;
  Duration recordingDuration = Duration.zero;
  DateTime? reminderAt;
  String reminderLabel = '';
  String? recordingPath;
  NoteItem? currentNote;
  List<NoteItem> notes = [];
  Timer? recordingTimer;

  bool get inEditor => widget.noteId != null || currentNote != null;
  bool get canEdit => currentNote?.canEdit ?? true;

  int? get editingId {
    final id = widget.noteId ?? currentNote?.id;
    return id != null && id > 0 ? id : null;
  }

  @override
  void initState() {
    super.initState();
    recorder = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    widget.noteId == null ? _loadList() : _loadNote(widget.noteId!);
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    recorder.dispose();
    searchController.dispose();
    titleController.dispose();
    _disposeBlocks();
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
      _fillEditor(await service.getNote(id));
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _newNote({_NoteBlock? initialBlock}) {
    _fillEditor(const NoteItem(
      id: 0,
      title: '',
      plainText: '',
      color: '',
      labels: [],
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
      reminderAt: null,
      reminderLabel: '',
      updatedAt: null,
    ));
    if (initialBlock != null) {
      _disposeBlocks();
      blocks
        ..clear()
        ..add(initialBlock)
        ..add(_NoteBlock.text());
    }
    addMenuOpen = false;
    setState(() {});
  }

  void _fillEditor(NoteItem note) {
    currentNote = note;
    titleController.text = note.title;
    visibility = note.visibility;
    color = note.color;
    labels = List<String>.from(note.labels);
    isPinned = note.isPinned;
    isArchived = note.isArchived;
    reminderAt = note.reminderAt;
    reminderLabel = note.reminderLabel;
    collaborators
      ..clear()
      ..addAll(note.collaborators);
    _disposeBlocks();
    blocks
      ..clear()
      ..addAll(note.bodyJson.map((json) => _NoteBlock.fromJson(json)));
    if (blocks.isEmpty) blocks.add(_NoteBlock.text());
    if (!blocks.any((block) => block.type == 'text')) {
      blocks.add(_NoteBlock.text());
    }
  }

  void _disposeBlocks() {
    for (final block in blocks) {
      block.dispose();
    }
  }

  bool get _hasContent =>
      titleController.text.trim().isNotEmpty || blocks.any((b) => b.hasContent);

  Future<NoteItem?> _save({bool quiet = false, bool allowEmpty = false}) async {
    if (!allowEmpty && !_hasContent) {
      if (!quiet) _message('اكتب عنوان أو محتوى للملاحظة');
      return null;
    }

    setState(() => saving = true);
    try {
      final note = await service.saveNote(
        id: editingId,
        title: titleController.text.trim(),
        bodyJson: blocks
            .where((block) => allowEmpty || block.hasContent)
            .map((e) => e.toJson())
            .toList(),
        visibility: visibility,
        color: color,
        labels: labels,
        isPinned: isPinned,
        isArchived: isArchived,
        collaborators: collaborators,
        reminderAt: reminderAt,
        reminderLabel: reminderLabel.isEmpty ? null : reminderLabel,
      );
      _fillEditor(note);
      if (!quiet) _message('تم حفظ الملاحظة');
      return note;
    } catch (e) {
      if (!quiet) _message(e.toString());
      return null;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<int?> _ensureSaved() async {
    if (editingId != null) return editingId;
    final note = await _save(quiet: true, allowEmpty: true);
    return note?.id;
  }

  Future<void> _closeEditor() async {
    if (canEdit && _hasContent) {
      await _save(quiet: true);
    }
    if (widget.noteId != null) {
      Get.back();
      return;
    }
    setState(() {
      currentNote = null;
      _disposeBlocks();
      blocks.clear();
    });
    await _loadList();
  }

  Future<void> _pickAttachment({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? forcedType,
  }) async {
    final noteId = await _ensureSaved();
    if (noteId == null) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    final path = result?.files.first.path;
    if (path == null || path.isEmpty) return;

    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, path, type: forcedType);
      setState(() {
        blocks.add(_NoteBlock.attachment(
          attachment,
          drawing: forcedType == 'drawing',
        ));
      });
      await _save(quiet: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _newAttachmentNote({
    required FileType type,
    List<String>? allowedExtensions,
    String? forcedType,
  }) async {
    setState(() => addMenuOpen = false);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    final path = result?.files.first.path;
    if (path == null || path.isEmpty) return;

    _newNote();
    final noteId = await _ensureSaved();
    if (noteId == null) return;

    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, path, type: forcedType);
      setState(() {
        blocks.add(_NoteBlock.attachment(
          attachment,
          drawing: forcedType == 'drawing',
        ));
      });
      await _save(quiet: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _takePhoto() async {
    final capture =
        await Get.to<WhatsAppCapture>(() => const WhatsAppCameraScreen());
    if (capture == null || capture.path.isEmpty) return;
    final noteId = await _ensureSaved();
    if (noteId == null) return;
    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, capture.path, type: 'image');
      setState(() => blocks.add(_NoteBlock.attachment(attachment)));
      await _save(quiet: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _newCameraNote() async {
    setState(() => addMenuOpen = false);
    _newNote();
    await _takePhoto();
  }

  Future<void> _newRecordingNote() async {
    setState(() => addMenuOpen = false);
    _newNote();
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (recording || saving || !canEdit) return;
    var permission = await Permission.microphone.status;
    if (!permission.isGranted) {
      permission = await Permission.microphone.request();
    }
    if (!permission.isGranted) {
      _message('يجب السماح باستخدام الميكروفون لتسجيل ملاحظة صوتية');
      return;
    }

    final directory = await getTemporaryDirectory();
    recordingPath =
        '${directory.path}/note_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await recorder.record(path: recordingPath!);
      recordingTimer?.cancel();
      setState(() {
        recording = true;
        recordingPaused = false;
        recordingDuration = Duration.zero;
      });
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !recordingPaused) {
          setState(() => recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      _message('تعذر بدء التسجيل: $e');
    }
  }

  Future<void> _toggleRecordingPause() async {
    if (!recording) return;
    try {
      if (recordingPaused) {
        await recorder.record();
      } else {
        await recorder.pause();
      }
      if (mounted) setState(() => recordingPaused = !recordingPaused);
    } catch (e) {
      _message('تعذر إيقاف أو متابعة التسجيل: $e');
    }
  }

  Future<void> _cancelRecording() async {
    if (!recording) return;
    recordingTimer?.cancel();
    try {
      final path = await recorder.stop() ?? recordingPath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      recording = false;
      recordingPaused = false;
      recordingDuration = Duration.zero;
      recordingPath = null;
    });
  }

  Future<void> _stopAndAttachRecording() async {
    if (!recording) return;
    recordingTimer?.cancel();
    String? path;
    try {
      path = await recorder.stop() ?? recordingPath;
      if (mounted) {
        setState(() {
          recording = false;
          recordingPaused = false;
          recordingDuration = Duration.zero;
          recordingPath = null;
        });
      }
      if (path == null || !await File(path).exists()) return;
      final noteId = await _ensureSaved();
      if (noteId == null) return;
      setState(() => saving = true);
      final attachment = await service.uploadAttachment(
        noteId,
        path,
        type: 'audio',
      );
      setState(() => blocks.add(_NoteBlock.attachment(attachment)));
      await _save(quiet: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          recording = false;
          recordingPaused = false;
          recordingDuration = Duration.zero;
          recordingPath = null;
        });
      }
      _message('تعذر حفظ التسجيل: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addDrawing() async {
    final noteId = await _ensureSaved();
    if (noteId == null) return;
    final result = await Get.to<_DrawingResult>(() => const _DrawingScreen());
    if (result == null || result.path.isEmpty) return;
    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, result.path, type: 'drawing');
      setState(() => blocks.add(_NoteBlock.attachment(
            attachment,
            drawing: true,
            drawingStrokes: result.strokes,
          )));
      await _save(quiet: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _newDrawingNote() async {
    setState(() => addMenuOpen = false);
    final result = await Get.to<_DrawingResult>(() => const _DrawingScreen());
    if (result == null || result.path.isEmpty) return;

    _newNote();
    final noteId = await _ensureSaved();
    if (noteId == null) return;

    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, result.path, type: 'drawing');
      setState(() => blocks.add(_NoteBlock.attachment(
            attachment,
            drawing: true,
            drawingStrokes: result.strokes,
          )));
      await _save(quiet: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _openMediaViewer(
    List<MapEntry<int, _NoteBlock>> media,
    int initialIndex,
  ) async {
    final result = await Get.to<_MediaEditResult>(
      () => _NoteMediaViewer(
        media: media.map((entry) => entry.value).toList(),
        initialIndex: initialIndex,
      ),
    );
    if (result == null || result.path.isEmpty) return;

    final noteId = await _ensureSaved();
    if (noteId == null) return;

    final originalBlockIndex = media[result.mediaIndex].key;
    final oldBlock = blocks[originalBlockIndex];
    final oldAttachmentId = oldBlock.attachmentId;

    setState(() => saving = true);
    try {
      final attachment =
          await service.uploadAttachment(noteId, result.path, type: 'drawing');
      final replacement = _NoteBlock.attachment(
        attachment,
        drawing: true,
        drawingBackgroundUrl: result.backgroundImageUrl,
        drawingStrokes: result.strokes,
      );
      setState(() {
        blocks[originalBlockIndex] = replacement;
        oldBlock.dispose();
      });
      await _save(quiet: true);
      if (oldAttachmentId > 0 && oldAttachmentId != attachment.id) {
        await service.deleteAttachment(noteId, oldAttachmentId);
      }
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _addChecklist() {
    setState(() {
      blocks.add(_NoteBlock.checklist());
      if (!blocks.any((block) => block.type == 'text')) {
        blocks.add(_NoteBlock.text());
      }
    });
  }

  void _toggleHomeAddMenu() {
    setState(() => addMenuOpen = !addMenuOpen);
  }

  Future<void> _shareDialog() async {
    final users = await service.users();
    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) => _KeepSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              _sheetTitle('المعاونون'),
              SizedBox(height: 10.h),
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
              SizedBox(height: 8.h),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, index) {
                    final user = users[index];
                    final selected = collaborators
                        .firstWhereOrNull((c) => c.userId == user.id);
                    return ListTile(
                      leading: _personAvatar(user, radius: 18),
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
                              underline: const SizedBox.shrink(),
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
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    setState(() {});
                    Get.back();
                  },
                  child: const Text('تم'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _deleteNote() async {
    final id = editingId;
    if (id == null) {
      await _closeEditor();
      return;
    }
    try {
      await service.deleteNote(id);
      _message('تم حذف الملاحظة');
      if (widget.noteId != null) {
        Get.back();
      } else {
        setState(() => currentNote = null);
        await _loadList();
      }
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _makeCopy() async {
    final note = await service.saveNote(
      title: titleController.text.trim().isEmpty
          ? 'نسخة من الملاحظة'
          : '${titleController.text.trim()} - نسخة',
      bodyJson: blocks.map((e) => e.toJson()).toList(),
      visibility: 'private',
      color: color,
      labels: labels,
      isPinned: false,
      isArchived: false,
      collaborators: const [],
      reminderAt: null,
      reminderLabel: null,
    );
    _fillEditor(note);
    setState(() {});
    _message('تم إنشاء نسخة');
  }

  Future<void> _shareNoteExternally() async {
    try {
      if (canEdit && _hasContent) {
        await _save(quiet: true, allowEmpty: true);
      }

      final shareBundle = await _shareFiles();
      final text = _shareText(failedAttachments: shareBundle.failedLinks);
      final files = shareBundle.files;
      if (files.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: titleController.text.trim().isEmpty
                ? 'ملاحظة'
                : titleController.text.trim(),
            files: files,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: titleController.text.trim().isEmpty
                ? 'ملاحظة'
                : titleController.text.trim(),
          ),
        );
      }
    } catch (e) {
      _message('تعذرت مشاركة الملاحظة: $e');
    }
  }

  String _shareText({List<String> failedAttachments = const []}) {
    final lines = <String>[];
    final title = titleController.text.trim();
    if (title.isNotEmpty) {
      lines.add(title);
      lines.add('');
    }

    for (final block in blocks) {
      if (block.type == 'text') {
        final text = block.textController.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
          lines.add('');
        }
      } else if (block.type == 'checklist') {
        final items = block.checkItems
            .map((item) {
              final text = item.controller.text.trim();
              if (text.isEmpty) return '';
              return '${item.checked ? '☑' : '☐'} $text';
            })
            .where((text) => text.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          lines.addAll(items);
          lines.add('');
        }
      }
    }

    if (failedAttachments.isNotEmpty) {
      lines.add('مرفقات لم يتم تنزيلها:');
      lines.addAll(failedAttachments);
    }

    final text = lines.join('\n').trim();
    return text.isEmpty ? 'ملاحظة من Doctor Bike' : text;
  }

  List<_NoteBlock> get _attachmentBlocks {
    return blocks
        .where((block) =>
            (block.type == 'attachment' || block.type == 'drawing') &&
            block.attachmentUrl.trim().isNotEmpty)
        .toList();
  }

  Future<_NoteShareFiles> _shareFiles() async {
    final files = <XFile>[];
    final failedLinks = <String>[];
    final dir = await getTemporaryDirectory();
    final shareDir = Directory(p.join(dir.path, 'doctor_bike_note_share'));
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    for (final block in _attachmentBlocks) {
      final url = block.attachmentUrl.trim();
      if (url.isEmpty) continue;

      final uri = Uri.tryParse(url);
      if (uri == null) {
        failedLinks.add('${_attachmentDisplay(block).value}: $url');
        continue;
      }

      if (uri.scheme == 'file' || uri.scheme.isEmpty) {
        final localPath = uri.scheme == 'file' ? uri.toFilePath() : url;
        if (await File(localPath).exists()) {
          files.add(XFile(localPath));
        } else {
          failedLinks.add('${_attachmentDisplay(block).value}: $url');
        }
        continue;
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        failedLinks.add('${_attachmentDisplay(block).value}: $url');
        continue;
      }

      try {
        final extension = p.extension(uri.path).isEmpty
            ? _shareExtensionFor(block)
            : p.extension(uri.path);
        final filename =
            'note_attachment_${block.attachmentId}_${files.length}$extension';
        final path = p.join(shareDir.path, filename);
        await dio.Dio().download(url, path);
        if (await File(path).exists()) {
          files.add(XFile(path));
        } else {
          failedLinks.add('${_attachmentDisplay(block).value}: $url');
        }
      } catch (_) {
        failedLinks.add('${_attachmentDisplay(block).value}: $url');
      }
    }

    return _NoteShareFiles(files: files, failedLinks: failedLinks);
  }

  String _shareExtensionFor(_NoteBlock block) {
    if (block.type == 'drawing' || _looksLikeImage(block.attachmentUrl)) {
      return '.png';
    }
    if (_looksLikeAudio(block)) return '.m4a';
    final lower = block.attachmentUrl.toLowerCase();
    if (lower.contains('video')) return '.mp4';
    return '';
  }

  Future<void> _setReminder(DateTime? at, String label) async {
    setState(() {
      reminderAt = at;
      reminderLabel = at == null ? '' : label;
    });
    await _save(quiet: true, allowEmpty: true);
    if (at != null) _message('تم ضبط التذكير: $label');
  }

  DateTime _tomorrowAt(int hour) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
  }

  DateTime _nextSundayMorning() {
    final now = DateTime.now();
    var days = DateTime.sunday - now.weekday;
    if (days <= 0) days += 7;
    final date = now.add(Duration(days: days));
    return DateTime(date.year, date.month, date.day, 8);
  }

  Future<void> _pickReminderDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: reminderAt ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminderAt ?? _tomorrowAt(8)),
    );
    if (pickedTime == null) return;

    final at = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    await _setReminder(at, _formatReminder(at));
  }

  void _showReminderSheet() {
    final tomorrowMorning = _tomorrowAt(8);
    final tomorrowEvening = _tomorrowAt(18);
    final nextSunday = _nextSundayMorning();

    Get.bottomSheet(
      _KeepSheet(
        compact: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: Color(0xff1a73e8)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'ذكرني لاحقًا',
                    style:
                        TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 40.w, top: 4.h),
              child: Text(
                'سيتم إرسال التذكير لصاحب الملاحظة والمعاونين',
                style: TextStyle(
                  color: keepInk.withValues(alpha: 0.72),
                  fontSize: 14.sp,
                ),
              ),
            ),
            Divider(height: 28.h),
            _reminderAction(
              'غدًا صباحًا',
              '8:00 ص',
              () {
                Get.back();
                _setReminder(tomorrowMorning, 'غدًا صباحًا');
              },
            ),
            _reminderAction(
              'غدًا مساءً',
              '6:00 م',
              () {
                Get.back();
                _setReminder(tomorrowEvening, 'غدًا مساءً');
              },
            ),
            _reminderAction(
              'الأحد القادم',
              '8:00 ص',
              () {
                Get.back();
                _setReminder(nextSunday, 'الأحد القادم');
              },
            ),
            _reminderAction(
              'اختيار تاريخ ووقت',
              '',
              () {
                Get.back();
                _pickReminderDateTime();
              },
            ),
            if (reminderAt != null)
              _sheetAction(Icons.close_rounded, 'إزالة التذكير', () {
                Get.back();
                _setReminder(null, '');
              }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddSheet() {
    Get.bottomSheet(
      _KeepSheet(
        compact: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetAction(Icons.photo_camera_outlined, 'التقاط صورة', () {
              Get.back();
              _takePhoto();
            }),
            _sheetAction(Icons.image_outlined, 'إضافة صورة', () {
              Get.back();
              _pickAttachment(
                type: FileType.custom,
                allowedExtensions: const [
                  'jpg',
                  'jpeg',
                  'png',
                  'webp',
                  'heic',
                  'heif',
                ],
                forcedType: 'image',
              );
            }),
            _sheetAction(Icons.brush_outlined, 'رسم', () {
              Get.back();
              _addDrawing();
            }),
            _sheetAction(Icons.mic_none_rounded, 'تسجيل صوتي', () {
              Get.back();
              _startRecording();
            }),
            _sheetAction(Icons.check_box_outlined, 'قائمة اختيار', () {
              Get.back();
              _addChecklist();
            }),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet() {
    Get.bottomSheet(
      _KeepSheet(
        compact: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: 6.w, bottom: 8.h),
              child: Text(
                editingId == null ? 'تم التعديل الآن' : 'تم التعديل الآن',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
              ),
            ),
            _sheetAction(Icons.delete_outline_rounded, 'حذف', () {
              Get.back();
              _deleteNote();
            }),
            _sheetAction(Icons.copy_rounded, 'إنشاء نسخة', () {
              Get.back();
              _makeCopy();
            }),
            _sheetAction(Icons.share_outlined, 'إرسال', () {
              Get.back();
              _shareNoteExternally();
            }),
            _sheetAction(Icons.person_add_alt_outlined, 'المعاونون', () {
              Get.back();
              _shareDialog();
            }),
            _sheetAction(Icons.label_outline_rounded, 'تصنيفات', () {
              Get.back();
              _showLabelsSheet();
            }),
            _sheetAction(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                isArchived ? 'إلغاء الأرشفة' : 'أرشفة', () {
              Get.back();
              setState(() => isArchived = !isArchived);
              _save(quiet: true, allowEmpty: true);
            }),
            _sheetAction(Icons.help_outline_rounded, 'مساعدة وملاحظات', () {
              Get.back();
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return inEditor ? _editorScaffold() : _listScaffold();
  }

  Widget _listScaffold() {
    final pinned = notes.where((note) => note.isPinned).toList();
    final others = notes.where((note) => !note.isPinned).toList();

    return Scaffold(
      backgroundColor: keepBackground,
      bottomNavigationBar: _notesAppBottomBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleHomeAddMenu,
        backgroundColor:
            addMenuOpen ? const Color(0xffa86112) : const Color(0xffffd5b8),
        foregroundColor: addMenuOpen ? Colors.white : keepInk,
        elevation: 9,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Icon(
          addMenuOpen ? Icons.close_rounded : Icons.add_rounded,
          size: 39.sp,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadList,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _keepSearchBar()),
                        SliverToBoxAdapter(child: _scopeStrip()),
                        if (notes.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'لا توجد ملاحظات',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: keepMuted,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          if (pinned.isNotEmpty) _sectionHeader('المثبتة'),
                          if (pinned.isNotEmpty) _notesGrid(pinned),
                          if (pinned.isNotEmpty && others.isNotEmpty)
                            _sectionHeader('أخرى'),
                          if (others.isNotEmpty) _notesGrid(others),
                          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
                        ],
                      ],
                    ),
                  ),
            if (addMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleHomeAddMenu,
                  child: Container(color: Colors.black.withValues(alpha: 0.58)),
                ),
              ),
            if (addMenuOpen)
              PositionedDirectional(
                end: 18.w,
                bottom: 92.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _homeAddOption(
                      Icons.photo_camera_outlined,
                      'كاميرا',
                      _newCameraNote,
                    ),
                    _homeAddOption(
                      Icons.image_outlined,
                      'صورة',
                      () => _newAttachmentNote(
                        type: FileType.custom,
                        allowedExtensions: const [
                          'jpg',
                          'jpeg',
                          'png',
                          'webp',
                          'heic',
                          'heif',
                        ],
                        forcedType: 'image',
                      ),
                    ),
                    _homeAddOption(
                      Icons.brush_rounded,
                      'رسم',
                      _newDrawingNote,
                    ),
                    _homeAddOption(
                      Icons.mic_none_rounded,
                      'تسجيل',
                      _newRecordingNote,
                    ),
                    _homeAddOption(
                      Icons.check_box_rounded,
                      'قائمة',
                      () => _newNote(initialBlock: _NoteBlock.checklist()),
                    ),
                    _homeAddOption(
                      Icons.text_fields_rounded,
                      'نص',
                      _newNote,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _homeAddOption(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Material(
        color: const Color(0xffffd5b8),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Container(
            height: 64.h,
            constraints: BoxConstraints(minWidth: 154.w),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: keepInk, size: 30.sp),
                SizedBox(width: 18.w),
                Text(
                  label,
                  style: TextStyle(
                    color: keepInk,
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesAppBottomBar() {
    final role =
        sessionUserType.value.isNotEmpty ? sessionUserType.value : userType;
    return SafeArea(
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _notesNavItem(
              icon: Icons.home_outlined,
              label: 'home'.tr,
              onTap: () => _goToShellIndex(0),
            ),
            _notesNavItem(
              icon: role == 'admin'
                  ? Icons.insert_chart_outlined_rounded
                  : Icons.check_circle_outline_rounded,
              label: role == 'admin' ? 'statistics'.tr : 'tasks'.tr,
              onTap: () => _goToShellIndex(1),
            ),
            _notesNavItem(
              icon: Icons.person_outline_rounded,
              label: 'profile'.tr,
              onTap: () => _goToShellIndex(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: keepInk.withValues(alpha: 0.76), size: 25.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: keepInk.withValues(alpha: 0.76),
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToShellIndex(int index) {
    if (Get.isRegistered<BottomNavBarController>()) {
      Get.find<BottomNavBarController>().changePage(index);
    }
    Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
  }

  Widget _keepSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu_rounded, size: 30.sp, color: keepInk),
          ),
          Expanded(
            child: Container(
              height: 58.h,
              padding: EdgeInsetsDirectional.only(start: 18.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => _loadList(),
                      decoration: InputDecoration(
                        hintText: 'بحث في الملاحظات',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 20.sp,
                          color: keepInk.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: gridView ? 'قائمة' : 'شبكة',
                    onPressed: () => setState(() => gridView = !gridView),
                    icon: Icon(
                      gridView
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_rounded,
                      color: keepInk,
                    ),
                  ),
                  IconButton(
                    tooltip: 'تحديث',
                    onPressed: _loadList,
                    icon: const Icon(Icons.swap_vert_rounded, color: keepInk),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xffffd5b8),
            child: Text(
              userName.isEmpty ? 'م' : userName.characters.first,
              style:
                  const TextStyle(color: keepInk, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeStrip() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _scopeChip('active', 'النشطة'),
          _scopeChip('mine', 'ملاحظاتي'),
          _scopeChip('shared', 'مشاركة معي'),
          _scopeChip('public', 'عامة'),
          _scopeChip('archived', 'الأرشيف'),
        ],
      ),
    );
  }

  Widget _scopeChip(String value, String label) {
    final selected = scope == value;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xffffd5b8),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        side: BorderSide(
          color: selected ? const Color(0xffffc59e) : const Color(0xffe4d4c7),
        ),
        onSelected: (_) {
          setState(() => scope = value);
          _loadList();
        },
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 8.h),
        child: Text(
          title,
          style: TextStyle(
            color: keepMuted,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _notesGrid(List<NoteItem> items) {
    if (!gridView) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(children: items.map(_noteCard).toList()),
        ),
      );
    }

    final left = <NoteItem>[];
    final right = <NoteItem>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? left : right).add(items[i]);
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left.map(_noteCard).toList())),
            SizedBox(width: 10.w),
            Expanded(child: Column(children: right.map(_noteCard).toList())),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(NoteItem note) {
    final preview = _firstVisualBlock(note);
    final collaboratorUsers =
        note.collaborators.map((e) => e.user).whereType<NoteUser>().toList();
    return InkWell(
      onTap: () => _loadNote(note.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: _noteColor(note.color),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffd7c8bd), width: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (preview != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: Image.network(
                  preview.attachmentUrl,
                  height: 92.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.title.trim().isNotEmpty)
                    Text(
                      note.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: keepInk,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (note.plainText.trim().isNotEmpty)
                    Padding(
                      padding:
                          EdgeInsets.only(top: note.title.isEmpty ? 0 : 8.h),
                      child: Text(
                        note.plainText,
                        maxLines: _cardTextLines(note),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: keepInk.withValues(alpha: 0.82),
                          fontSize: 15.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (note.labels.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: _labelsWrap(note.labels, compact: true),
                    ),
                  if (collaboratorUsers.isNotEmpty ||
                      note.attachmentsCount > 0 ||
                      note.reminderAt != null ||
                      note.visibility == 'public')
                    Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Row(
                        children: [
                          if (note.reminderAt != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xffffd5b8)
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 13.sp, color: keepMuted),
                                  SizedBox(width: 3.w),
                                  Text(
                                    note.reminderLabel.isEmpty
                                        ? _formatReminder(note.reminderAt!)
                                        : note.reminderLabel,
                                    style: TextStyle(
                                      color: keepMuted,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (note.reminderAt != null &&
                              collaboratorUsers.isNotEmpty)
                            SizedBox(width: 6.w),
                          if (collaboratorUsers.isNotEmpty)
                            _avatarStack(collaboratorUsers),
                          const Spacer(),
                          if (note.attachmentsCount > 0)
                            Icon(Icons.attach_file_rounded,
                                size: 15.sp, color: keepMuted),
                          if (note.visibility == 'public')
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: 4.w),
                              child: Icon(Icons.public_rounded,
                                  size: 15.sp, color: keepMuted),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _cardTextLines(NoteItem note) {
    final length = note.plainText.length + note.title.length;
    if (length > 220) return 10;
    if (length > 110) return 7;
    return 4;
  }

  _NoteBlock? _firstVisualBlock(NoteItem note) {
    for (final raw in note.bodyJson) {
      final block = _NoteBlock.fromJson(raw);
      if ((block.type == 'attachment' || block.type == 'drawing') &&
          block.attachmentUrl.isNotEmpty &&
          _looksLikeImage(block.attachmentUrl)) {
        return block;
      }
      block.dispose();
    }
    return null;
  }

  List<MapEntry<int, _NoteBlock>> get _mediaEntries {
    return blocks.asMap().entries.where((entry) {
      final block = entry.value;
      return (block.type == 'attachment' || block.type == 'drawing') &&
          block.attachmentUrl.isNotEmpty &&
          _looksLikeImage(block.attachmentUrl);
    }).toList();
  }

  List<MapEntry<int, _NoteBlock>> get _attachmentEntries {
    return blocks.asMap().entries.where((entry) {
      final block = entry.value;
      return (block.type == 'attachment' || block.type == 'drawing') &&
          block.attachmentUrl.isNotEmpty &&
          !_looksLikeAudio(block);
    }).toList();
  }

  List<MapEntry<int, _NoteBlock>> get _audioEntries {
    return blocks.asMap().entries.where((entry) {
      final block = entry.value;
      return (block.type == 'attachment' || block.type == 'drawing') &&
          block.attachmentUrl.isNotEmpty &&
          _looksLikeAudio(block);
    }).toList();
  }

  Widget _editorScaffold() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeEditor();
      },
      child: Scaffold(
        backgroundColor: _noteColor(color),
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _editorTopBar(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(28.w, 22.h, 28.w, 24.h),
                        children: [
                          if (_attachmentEntries.isNotEmpty)
                            _attachmentsStrip(),
                          if (_attachmentEntries.isNotEmpty)
                            SizedBox(height: 22.h),
                          if (_audioEntries.isNotEmpty) _audioList(),
                          if (_audioEntries.isNotEmpty) SizedBox(height: 22.h),
                          if (labels.isNotEmpty) ...[
                            _labelsWrap(labels),
                            SizedBox(height: 12.h),
                          ],
                          TextField(
                            controller: titleController,
                            enabled: canEdit,
                            style: TextStyle(
                              color: keepInk,
                              fontSize: 27.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                            decoration: InputDecoration(
                              hintText: 'العنوان',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: keepMuted.withValues(alpha: 0.45),
                                fontSize: 27.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ...blocks.asMap().entries.where((entry) {
                            final block = entry.value;
                            return block.type != 'attachment' &&
                                block.type != 'drawing';
                          }).map((entry) {
                            return _blockWidget(
                              entry.key,
                              entry.value,
                              canEdit,
                            );
                          }),
                        ],
                      ),
                    ),
                    _editorBottomBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _attachmentsStrip() {
    final attachments = _attachmentEntries;
    final media = _mediaEntries;
    return SizedBox(
      height: 300.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => SizedBox(width: 18.w),
        itemBuilder: (_, index) {
          final entry = attachments[index];
          final block = entry.value;
          final isImage = _looksLikeImage(block.attachmentUrl);
          final mediaIndex =
              media.indexWhere((mediaEntry) => mediaEntry.key == entry.key);

          return SizedBox(
            width: 216.w,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (isImage && mediaIndex >= 0) {
                        _openMediaViewer(media, mediaIndex);
                      } else if (block.attachmentUrl.isNotEmpty) {
                        launchUrl(Uri.parse(block.attachmentUrl));
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isImage
                          ? Image.network(
                              block.attachmentUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _attachmentTile(
                                block,
                                icon: Icons.broken_image_outlined,
                              ),
                            )
                          : _attachmentTile(block),
                    ),
                  ),
                ),
                if (canEdit)
                  PositionedDirectional(
                    top: 8.h,
                    end: 8.w,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.48),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _removeAttachmentBlock(entry.key),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 21.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _attachmentTile(_NoteBlock block, {IconData? icon}) {
    final data = _attachmentDisplay(block);
    return Container(
      color: keepSheet,
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? data.key, color: keepInk, size: 52.sp),
          SizedBox(height: 12.h),
          Text(
            data.value,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: keepInk,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelsWrap(List<String> items, {bool compact = false}) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: items
          .map(
            (label) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7.w : 10.w,
                vertical: compact ? 3.h : 5.h,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffffd5b8).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xffedc2a3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: keepInk.withValues(alpha: 0.84),
                  fontSize: compact ? 10.sp : 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _audioList() {
    final audios = _audioEntries;
    return Column(
      children: [
        for (final entry in audios)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _NoteAudioBubble(
              block: entry.value,
              canEdit: canEdit,
              onDelete: () => _removeAttachmentBlock(entry.key),
            ),
          ),
      ],
    );
  }

  Widget _editorTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: _closeEditor,
            icon: Icon(Icons.arrow_back_rounded, color: keepInk, size: 30.sp),
          ),
          const Spacer(),
          _softIconButton(
            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            () => setState(() => isPinned = !isPinned),
          ),
          _softIconButton(
            reminderAt == null
                ? Icons.add_alert_outlined
                : Icons.notifications_active_outlined,
            _showReminderSheet,
          ),
        ],
      ),
    );
  }

  Widget _editorBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 10.h),
      decoration: BoxDecoration(
        color: _noteColor(color).withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: recording
          ? _recordingBar()
          : Row(
              children: [
                _bottomTool(Icons.add_box_outlined, _showAddSheet),
                SizedBox(width: 18.w),
                _bottomTool(Icons.palette_outlined, _showColorSheet),
                SizedBox(width: 18.w),
                _bottomTool(Icons.format_color_text_rounded,
                    () => _message('سيتم إضافة تنسيق النص لاحقاً')),
                const Spacer(),
                _bottomTool(Icons.more_vert_rounded, _showMoreSheet),
              ],
            ),
    );
  }

  Widget _recordingBar() {
    return Row(
      children: [
        IconButton(
          tooltip: 'إلغاء التسجيل',
          onPressed: _cancelRecording,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        Expanded(
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: keepSheet,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xffe2d2c6)),
            ),
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record,
                    size: 13.sp, color: Colors.red.shade700),
                SizedBox(width: 7.w),
                Text(
                  _duration(recordingDuration),
                  style: TextStyle(
                    color: keepInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: AudioWaveforms(
                    size: Size(double.infinity, 30.h),
                    recorderController: recorder,
                    waveStyle: WaveStyle(
                      waveColor: const Color(0xffa86112).withValues(alpha: 0.8),
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: recordingPaused ? 'متابعة' : 'إيقاف مؤقت',
                  onPressed: _toggleRecordingPause,
                  icon: Icon(recordingPaused ? Icons.play_arrow : Icons.pause),
                  color: keepInk,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 6.w),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: const Color(0xffa86112)),
          onPressed: saving ? null : _stopAndAttachRecording,
          icon: const Icon(Icons.check_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _blockWidget(int index, _NoteBlock block, bool canEdit) {
    if (block.type == 'checklist') {
      return Padding(
        padding: EdgeInsets.only(top: 18.h),
        child: Column(
          children: [
            ...block.checkItems.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator_rounded,
                        color: keepInk.withValues(alpha: 0.75)),
                    SizedBox(width: 8.w),
                    Transform.scale(
                      scale: 1.18,
                      child: Checkbox(
                        value: item.checked,
                        side: const BorderSide(color: keepInk, width: 1.7),
                        onChanged: canEdit
                            ? (v) => setState(() => item.checked = v ?? false)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: item.controller,
                        enabled: canEdit,
                        style: TextStyle(fontSize: 20.sp, color: keepInk),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'عنصر',
                        ),
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: () =>
                            _removeChecklistItem(index, block, entry.key),
                        icon: Icon(Icons.close_rounded,
                            color: keepInk, size: 28.sp),
                      ),
                  ],
                ),
              );
            }),
            if (canEdit)
              Row(
                children: [
                  SizedBox(width: 72.w),
                  Icon(Icons.add_rounded, color: keepInk, size: 30.sp),
                  SizedBox(width: 16.w),
                  TextButton(
                    onPressed: () =>
                        setState(() => block.checkItems.add(_CheckItem())),
                    child: Text(
                      'إضافة عنصر',
                      style: TextStyle(
                        color: keepInk.withValues(alpha: 0.8),
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    if (block.type == 'attachment' || block.type == 'drawing') {
      final isImage = _looksLikeImage(block.attachmentUrl);
      return Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: block.attachmentUrl.isEmpty
              ? null
              : () => launchUrl(Uri.parse(block.attachmentUrl)),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    block.attachmentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _attachmentLine(block, canEdit),
                  ),
                )
              : _attachmentLine(block, canEdit),
        ),
      );
    }

    return TextField(
      controller: block.textController,
      enabled: canEdit,
      minLines: 8,
      maxLines: null,
      style: TextStyle(color: keepInk, fontSize: 20.sp, height: 1.45),
      decoration: InputDecoration(
        hintText: 'الوصف',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: keepMuted.withValues(alpha: 0.45),
          fontSize: 21.sp,
        ),
      ),
    );
  }

  Widget _attachmentLine(_NoteBlock block, bool canEdit) {
    final display = _attachmentDisplay(block);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(display.key, color: keepInk),
      title: Text(display.value),
      subtitle: Text(
        block.attachmentUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canEdit
          ? IconButton(
              onPressed: () => _removeAttachmentBlock(blocks.indexOf(block)),
              icon: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }

  void _removeChecklistItem(int blockIndex, _NoteBlock block, int itemIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    setState(() {
      block.checkItems.removeAt(itemIndex).dispose();
      if (block.checkItems.isEmpty) {
        blocks.removeAt(blockIndex);
        block.dispose();
      }
      if (!blocks.any((entry) => entry.type == 'text')) {
        blocks.add(_NoteBlock.text());
      }
    });
  }

  MapEntry<IconData, String> _attachmentDisplay(_NoteBlock block) {
    final label = block.attachmentName.trim().isEmpty
        ? 'Attachment'
        : block.attachmentName.trim();
    final lower = '${block.attachmentUrl} $label'.toLowerCase();

    if (block.type == 'drawing') {
      return MapEntry(Icons.brush_outlined, label == 'drawing' ? 'رسم' : label);
    }
    if (_looksLikeImage(lower)) {
      return MapEntry(Icons.image_outlined, label == 'image' ? 'صورة' : label);
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.contains('video')) {
      return MapEntry(
          Icons.videocam_outlined, label == 'video' ? 'فيديو' : label);
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav') ||
        lower.contains('audio')) {
      return MapEntry(
          Icons.mic_none_rounded, label == 'audio' ? 'تسجيل صوتي' : label);
    }

    return MapEntry(Icons.attach_file_rounded, label);
  }

  Future<void> _removeAttachmentBlock(int index) async {
    if (index < 0 || index >= blocks.length || !canEdit) return;
    final block = blocks[index];
    final noteId = editingId;
    final attachmentId = block.attachmentId;

    setState(() {
      blocks.removeAt(index);
      block.dispose();
    });

    try {
      await _save(quiet: true, allowEmpty: true);
      if (noteId != null && attachmentId > 0) {
        await service.deleteAttachment(noteId, attachmentId);
      }
    } catch (e) {
      _message(e.toString());
    }
  }

  void _showColorSheet() {
    Get.bottomSheet(
      _KeepSheet(
        compact: true,
        child: Wrap(
          spacing: 14.w,
          runSpacing: 12.h,
          children: colors
              .map(
                (c) => InkWell(
                  onTap: () {
                    setState(() => color = c);
                    Get.back();
                  },
                  child: CircleAvatar(
                    radius: 24.r,
                    backgroundColor: _noteColor(c),
                    child: color == c ? const Icon(Icons.check) : null,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLabelsSheet() {
    final controller = TextEditingController();
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) => _KeepSheet(
          compact: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetTitle('التصنيفات'),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final label in labels)
                    Chip(
                      label: Text(label),
                      deleteIcon: const Icon(Icons.close_rounded),
                      onDeleted: () {
                        setSheetState(() => labels.remove(label));
                        setState(() {});
                        _save(quiet: true, allowEmpty: true);
                      },
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'تصنيف جديد',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    _addLabelFromController(controller, setSheetState),
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () =>
                      _addLabelFromController(controller, setSheetState),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(controller.dispose);
  }

  void _addLabelFromController(
    TextEditingController controller,
    StateSetter setSheetState,
  ) {
    final label = controller.text.trim();
    if (label.isEmpty) return;
    setSheetState(() {
      if (!labels.contains(label)) labels.add(label);
      controller.clear();
    });
    setState(() {});
    _save(quiet: true, allowEmpty: true);
  }

  Widget _softIconButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 10.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canEdit ? onTap : null,
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: const Color(0xfffff0e5).withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: keepInk, size: 28.sp),
        ),
      ),
    );
  }

  Widget _bottomTool(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: canEdit ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: const Color(0xfffff0e5).withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: keepInk, size: 26.sp),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: keepInk, size: 28.sp),
      title: Text(
        label,
        style: TextStyle(fontSize: 19.sp, color: keepInk),
      ),
      onTap: onTap,
    );
  }

  Widget _reminderAction(String label, String time, VoidCallback onTap) {
    return ListTile(
      leading: Icon(Icons.access_time_rounded, color: keepInk, size: 29.sp),
      title: Text(
        label,
        style: TextStyle(fontSize: 19.sp, color: keepInk),
      ),
      trailing: time.isEmpty
          ? null
          : Text(
              time,
              style: TextStyle(fontSize: 18.sp, color: keepInk),
            ),
      onTap: onTap,
    );
  }

  Widget _sheetTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.w800),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xffdacbc0),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _avatarStack(List<NoteUser> users) {
    final shown = users.take(3).toList();
    return SizedBox(
      width: 22.w + (shown.length - 1) * 14.w,
      height: 24.w,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * 14.w,
              child: _personAvatar(shown[i], radius: 12),
            ),
        ],
      ),
    );
  }

  Widget _personAvatar(NoteUser user, {required double radius}) {
    final image = user.imageUrl.trim();
    final url = image.isEmpty ? '' : ShowNetImage.getPhoto(image);
    final initials = _initials(user.name);
    return CircleAvatar(
      radius: radius.r,
      backgroundColor: const Color(0xffffd5b8),
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isNotEmpty
          ? null
          : Text(
              initials,
              style: TextStyle(
                color: keepInk,
                fontSize: (radius * (initials.length > 1 ? 0.62 : 0.85)).sp,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters
        .where((ch) => ch.trim().isNotEmpty)
        .take(2)
        .join();
  }

  bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('image');
  }

  bool _looksLikeAudio(_NoteBlock block) {
    final lower =
        '${block.attachmentUrl} ${block.attachmentName}'.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav') ||
        lower.contains('audio') ||
        lower.contains('voice');
  }

  String _formatReminder(DateTime at) {
    final now = DateTime.now();
    final date = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final suffix = at.hour >= 12 ? 'م' : 'ص';
    final time = '$hour:$minute $suffix';

    if (date == today) return 'اليوم $time';
    if (date == tomorrow) return 'غدًا $time';

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
      'ديسمبر',
    ];
    return '${months[at.month - 1]} ${at.day}, $time';
  }

  String _duration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        return keepSheet;
    }
  }

  void _message(String text) {
    Get.snackbar('الملاحظات', text, snackPosition: SnackPosition.BOTTOM);
  }
}

class _KeepSheet extends StatelessWidget {
  final Widget child;
  final bool compact;

  const _KeepSheet({required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: compact ? null : BoxConstraints(maxHeight: 0.82.sh),
      padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 18.h),
      decoration: const BoxDecoration(
        color: _NotesScreenState.keepSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class _NoteAudioBubble extends StatefulWidget {
  final _NoteBlock block;
  final bool canEdit;
  final VoidCallback onDelete;

  const _NoteAudioBubble({
    required this.block,
    required this.canEdit,
    required this.onDelete,
  });

  @override
  State<_NoteAudioBubble> createState() => _NoteAudioBubbleState();
}

class _NoteAudioBubbleState extends State<_NoteAudioBubble> {
  final player = ja.AudioPlayer();
  bool loading = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await player.setUrl(widget.block.attachmentUrl);
    } catch (e) {
      error = e;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 58.h,
        alignment: Alignment.center,
        decoration: _bubbleDecoration(),
        child: const LinearProgressIndicator(color: Color(0xffa86112)),
      );
    }

    if (error != null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: _bubbleDecoration(),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8.w),
            const Expanded(child: Text('تعذر تحميل التسجيل الصوتي')),
            if (widget.canEdit)
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: _bubbleDecoration(),
      child: Row(
        children: [
          StreamBuilder<ja.PlayerState>(
            stream: player.playerStateStream,
            builder: (_, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing == true;
              final completed =
                  state?.processingState == ja.ProcessingState.completed;
              return IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xffa86112),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (completed) await player.seek(Duration.zero);
                  playing ? await player.pause() : await player.play();
                },
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snapshot) {
                final duration = player.duration ?? Duration.zero;
                final position = snapshot.data ?? Duration.zero;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.h,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: const Color(0xffa86112),
                        inactiveTrackColor: const Color(0xffe2d2c6),
                        thumbColor: const Color(0xffa86112),
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds
                            .clamp(1, 1 << 31)
                            .toDouble(),
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        onChanged: (value) => player.seek(
                          Duration(milliseconds: value.round()),
                        ),
                      ),
                    ),
                    Text(
                      '${_noteDuration(position)} / ${_noteDuration(duration)}',
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: _NotesScreenState.keepMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Icon(Icons.mic_none_rounded,
              color: const Color(0xffa86112), size: 24.sp),
          if (widget.canEdit)
            IconButton(
              tooltip: 'حذف التسجيل',
              onPressed: widget.onDelete,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  BoxDecoration _bubbleDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: const Color(0xffe2d2c6)),
    );
  }
}

String _noteDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _NoteShareFiles {
  final List<XFile> files;
  final List<String> failedLinks;

  const _NoteShareFiles({
    required this.files,
    required this.failedLinks,
  });
}

class _NoteBlock {
  final String type;
  final TextEditingController textController;
  final List<_CheckItem> checkItems;
  final int attachmentId;
  final String attachmentUrl;
  final String attachmentName;
  final String drawingBackgroundUrl;
  final List<Map<String, dynamic>> drawingStrokes;

  _NoteBlock({
    required this.type,
    TextEditingController? textController,
    List<_CheckItem>? checkItems,
    this.attachmentId = 0,
    this.attachmentUrl = '',
    this.attachmentName = '',
    this.drawingBackgroundUrl = '',
    this.drawingStrokes = const [],
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

  factory _NoteBlock.attachment(
    NoteAttachment attachment, {
    bool drawing = false,
    String drawingBackgroundUrl = '',
    List<Map<String, dynamic>> drawingStrokes = const [],
  }) =>
      _NoteBlock(
        type:
            drawing || attachment.type == 'drawing' ? 'drawing' : 'attachment',
        attachmentId: attachment.id,
        attachmentUrl: attachment.url,
        attachmentName: attachment.originalName.isEmpty
            ? attachment.type
            : attachment.originalName,
        drawingBackgroundUrl: drawingBackgroundUrl,
        drawingStrokes: drawingStrokes,
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
        drawingBackgroundUrl: json['drawing_background_url']?.toString() ?? '',
        drawingStrokes: (json['drawing_strokes'] is List
                ? json['drawing_strokes'] as List
                : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
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
      final payload = {
        'type': type,
        'attachment_id': attachmentId,
        'url': attachmentUrl,
        'name': attachmentName,
      };
      if (type == 'drawing') {
        payload['drawing_background_url'] = drawingBackgroundUrl;
        payload['drawing_strokes'] = drawingStrokes;
      }
      return payload;
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

enum _DrawingTool { pen, brush, highlighter, eraser, strokeEraser }

class _DrawingStroke {
  final _DrawingTool tool;
  final Color color;
  final double width;
  final List<Offset> points;

  _DrawingStroke({
    required this.tool,
    required this.color,
    required this.width,
    List<Offset>? points,
  }) : points = points ?? [];

  factory _DrawingStroke.fromJson(Map<String, dynamic> json) {
    final tool = _drawingToolFromJson(json['tool']?.toString());
    final points = (json['points'] is List ? json['points'] as List : const [])
        .whereType<Map>()
        .map((point) {
          final x = double.tryParse(point['x']?.toString() ?? '');
          final y = double.tryParse(point['y']?.toString() ?? '');
          return x == null || y == null ? null : Offset(x, y);
        })
        .whereType<Offset>()
        .toList();

    return _DrawingStroke(
      tool: tool,
      color: Color(int.tryParse(json['color']?.toString() ?? '') ?? 0xff000000),
      width: double.tryParse(json['width']?.toString() ?? '') ?? 4,
      points: points,
    );
  }

  Map<String, dynamic> toJson() => {
        'tool': _drawingToolToJson(tool),
        // ignore: deprecated_member_use
        'color': color.value,
        'width': width,
        'points':
            points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
      };
}

_DrawingTool _drawingToolFromJson(String? value) {
  switch (value) {
    case 'brush':
      return _DrawingTool.brush;
    case 'highlighter':
      return _DrawingTool.highlighter;
    case 'eraser':
      return _DrawingTool.eraser;
    case 'strokeEraser':
      return _DrawingTool.strokeEraser;
    default:
      return _DrawingTool.pen;
  }
}

String _drawingToolToJson(_DrawingTool tool) {
  switch (tool) {
    case _DrawingTool.brush:
      return 'brush';
    case _DrawingTool.highlighter:
      return 'highlighter';
    case _DrawingTool.eraser:
      return 'eraser';
    case _DrawingTool.strokeEraser:
      return 'strokeEraser';
    case _DrawingTool.pen:
      return 'pen';
  }
}

class _DrawingResult {
  final String path;
  final List<Map<String, dynamic>> strokes;

  const _DrawingResult({
    required this.path,
    required this.strokes,
  });
}

class _DrawingScreen extends StatefulWidget {
  final String? backgroundImageUrl;
  final List<Map<String, dynamic>> initialStrokes;

  const _DrawingScreen({
    this.backgroundImageUrl,
    this.initialStrokes = const [],
  });

  @override
  State<_DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<_DrawingScreen> {
  final key = GlobalKey();
  final strokes = <_DrawingStroke>[];
  final undoneStrokes = <_DrawingStroke>[];
  Color color = Colors.black;
  double strokeWidth = 4;
  _DrawingTool tool = _DrawingTool.pen;
  _DrawingStroke? activeStroke;

  @override
  void initState() {
    super.initState();
    strokes.addAll(
      widget.initialStrokes.map((json) => _DrawingStroke.fromJson(json)),
    );
  }

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
    Get.back(
      result: _DrawingResult(
        path: file.path,
        strokes: strokes.map((stroke) => stroke.toJson()).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NotesScreenState.keepSheet,
      appBar: AppBar(
        title: const Text('الرسم'),
        backgroundColor: _NotesScreenState.keepSheet,
        actions: [
          IconButton(
            tooltip: 'مسح الكل',
            onPressed: () => setState(() {
              undoneStrokes
                ..clear()
                ..addAll(strokes);
              strokes.clear();
            }),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'تراجع',
            onPressed: strokes.isEmpty
                ? null
                : () => setState(() => undoneStrokes.add(strokes.removeLast())),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'إعادة',
            onPressed: undoneStrokes.isEmpty
                ? null
                : () => setState(() => strokes.add(undoneStrokes.removeLast())),
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Column(
        children: [
          _drawingToolbar(),
          Expanded(
            child: RepaintBoundary(
              key: key,
              child: GestureDetector(
                onPanStart: (details) {
                  final point = _toCanvasPoint(details.globalPosition);
                  if (point == null) return;
                  if (tool == _DrawingTool.strokeEraser) {
                    setState(() => _eraseStrokeAt(point));
                    return;
                  }
                  setState(() {
                    activeStroke = _DrawingStroke(
                      tool: tool,
                      color: _activeColor,
                      width: _activeWidth,
                      points: [point],
                    );
                    strokes.add(activeStroke!);
                    undoneStrokes.clear();
                  });
                },
                onPanUpdate: (details) {
                  final point = _toCanvasPoint(details.globalPosition);
                  if (tool == _DrawingTool.strokeEraser) {
                    if (point != null) setState(() => _eraseStrokeAt(point));
                    return;
                  }
                  if (point == null || activeStroke == null) return;
                  setState(() => activeStroke!.points.add(point));
                },
                onPanEnd: (_) => activeStroke = null,
                onPanCancel: () => activeStroke = null,
                child: CustomPaint(
                  foregroundPainter: _DrawingPainter(strokes),
                  child: Container(
                    color: Colors.white,
                    child: widget.backgroundImageUrl == null
                        ? null
                        : Image.network(
                            widget.backgroundImageUrl!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset? _toCanvasPoint(Offset globalPosition) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition);
  }

  Color get _activeColor {
    if (tool == _DrawingTool.highlighter) {
      return color.withValues(alpha: 0.34);
    }
    return color;
  }

  double get _activeWidth {
    switch (tool) {
      case _DrawingTool.pen:
        return strokeWidth;
      case _DrawingTool.brush:
        return strokeWidth * 1.7;
      case _DrawingTool.highlighter:
        return strokeWidth * 2.6;
      case _DrawingTool.eraser:
        return strokeWidth * 2.4;
      case _DrawingTool.strokeEraser:
        return strokeWidth * 2.4;
    }
  }

  void _eraseStrokeAt(Offset point) {
    for (var i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
      if (stroke.tool == _DrawingTool.eraser ||
          stroke.tool == _DrawingTool.strokeEraser) {
        continue;
      }
      if (_strokeHitsPoint(stroke, point, _activeWidth / 2)) {
        undoneStrokes.add(strokes.removeAt(i));
        break;
      }
    }
  }

  bool _strokeHitsPoint(_DrawingStroke stroke, Offset point, double padding) {
    final threshold = (stroke.width / 2) + padding + 6;
    for (var i = 0; i < stroke.points.length; i++) {
      if ((stroke.points[i] - point).distance <= threshold) return true;
      if (i == 0) continue;
      if (_distanceToSegment(point, stroke.points[i - 1], stroke.points[i]) <=
          threshold) {
        return true;
      }
    }
    return false;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final segment = b - a;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * segment.dx + (p.dy - a.dy) * segment.dy) /
            lengthSquared)
        .clamp(0.0, 1.0);
    final projection = Offset(a.dx + segment.dx * t, a.dy + segment.dy * t);
    return (p - projection).distance;
  }

  Widget _drawingToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
      color: _NotesScreenState.keepSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _toolButton(Icons.edit_outlined, _DrawingTool.pen, 'قلم'),
              _toolButton(Icons.brush_outlined, _DrawingTool.brush, 'فرشاة'),
              _toolButton(
                Icons.border_color_outlined,
                _DrawingTool.highlighter,
                'هايلايتر',
              ),
              _toolButton(
                Icons.cleaning_services_outlined,
                _DrawingTool.eraser,
                'محاية عادية',
              ),
              _toolButton(
                Icons.auto_fix_off_outlined,
                _DrawingTool.strokeEraser,
                'مسح خط كامل',
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Slider(
                  value: strokeWidth,
                  min: 1,
                  max: 16,
                  onChanged: (v) => setState(() => strokeWidth = v),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in [
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow.shade700,
                  Colors.white,
                ])
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: InkWell(
                      onTap: () => setState(() {
                        color = c;
                        if (tool == _DrawingTool.eraser) {
                          tool = _DrawingTool.pen;
                        }
                      }),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == c
                                ? const Color(0xffa86112)
                                : Colors.black.withValues(alpha: 0.18),
                            width: color == c ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, _DrawingTool value, String tooltip) {
    final selected = tool == value;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 6.w),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xffffd5b8) : const Color(0xfffff4ed),
          foregroundColor: _NotesScreenState.keepInk,
        ),
        onPressed: () => setState(() => tool = value),
        icon: Icon(icon),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;

  const _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width;

      if (stroke.tool == _DrawingTool.eraser) {
        paint.blendMode = BlendMode.clear;
      }

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final previous = stroke.points[i - 1];
        final current = stroke.points[i];
        final midpoint = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(
            previous.dx, previous.dy, midpoint.dx, midpoint.dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _MediaEditResult {
  final int mediaIndex;
  final String path;
  final String backgroundImageUrl;
  final List<Map<String, dynamic>> strokes;

  const _MediaEditResult({
    required this.mediaIndex,
    required this.path,
    required this.backgroundImageUrl,
    required this.strokes,
  });
}

class _NoteMediaViewer extends StatefulWidget {
  final List<_NoteBlock> media;
  final int initialIndex;

  const _NoteMediaViewer({
    required this.media,
    required this.initialIndex,
  });

  @override
  State<_NoteMediaViewer> createState() => _NoteMediaViewerState();
}

class _NoteMediaViewerState extends State<_NoteMediaViewer> {
  late final PageController controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _drawOverCurrent() async {
    final block = widget.media[index];
    final backgroundUrl = block.drawingBackgroundUrl.isNotEmpty
        ? block.drawingBackgroundUrl
        : (block.type == 'drawing' && block.drawingStrokes.isNotEmpty
            ? ''
            : block.attachmentUrl);
    final result = await Get.to<_DrawingResult>(
      () => _DrawingScreen(
        backgroundImageUrl: backgroundUrl.isEmpty ? null : backgroundUrl,
        initialStrokes: block.drawingStrokes,
      ),
    );
    if (result != null && result.path.isNotEmpty) {
      Get.back(
        result: _MediaEditResult(
          mediaIndex: index,
          path: result.path,
          backgroundImageUrl: backgroundUrl,
          strokes: result.strokes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NotesScreenState.keepSheet,
      appBar: AppBar(
        backgroundColor: _NotesScreenState.keepBackground,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('${index + 1} من ${widget.media.length}'),
        actions: [
          IconButton(
            onPressed: _drawOverCurrent,
            icon: const Icon(Icons.brush_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: widget.media.length,
        onPageChanged: (value) => setState(() => index = value),
        itemBuilder: (_, page) {
          final block = widget.media[page];
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                block.attachmentUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  size: 64.sp,
                  color: _NotesScreenState.keepMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
