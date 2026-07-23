import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/helpers/custom_app_bar.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/user_data.dart';
import '../../../../core/utils/app_colors.dart';
import '../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import '../data/app_development_service.dart';

class AppDevelopmentScreen extends StatefulWidget {
  final int? taskId;

  const AppDevelopmentScreen({Key? key, this.taskId}) : super(key: key);

  @override
  State<AppDevelopmentScreen> createState() => _AppDevelopmentScreenState();
}

class _AppDevelopmentScreenState extends State<AppDevelopmentScreen> {
  final service = AppDevelopmentService();
  final searchController = TextEditingController();
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  late final RecorderController recorder;

  bool loading = true;
  bool sending = false;
  bool recording = false;
  bool recordingPaused = false;
  Duration recordingDuration = Duration.zero;
  String? recordingPath;
  Timer? recordingTimer;
  String status = 'all';
  Map<String, int> stats = {};
  List<AppDevelopmentTask> tasks = [];
  List<AppDevelopmentAdmin> developers = [];
  AppDevelopmentTask? task;
  int currentUserId = 0;

  bool get isDetails => widget.taskId != null;

  static const statuses = [
    ['all', 'الكل'],
    ['new', 'جديدة'],
    ['in_progress', 'قيد العمل'],
    ['waiting_owner', 'بانتظارك'],
    ['done', 'منجزة'],
    ['closed', 'مغلقة'],
  ];

  static const statusActions = [
    ['review', 'مراجعة'],
    ['in_progress', 'قيد العمل'],
    ['waiting_owner', 'بانتظار صاحب التطبيق'],
    ['done', 'منجزة'],
    ['closed', 'إغلاق'],
  ];

  @override
  void initState() {
    super.initState();
    recorder = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    _loadCurrentUser();
    isDetails ? _loadDetails() : _loadList();
    _loadMetadata();
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    recorder.dispose();
    searchController.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    try {
      final data = await service.metadata();
      developers = data['developers'] ?? [];
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    final saved = await UserData.getSavedUser();
    if (!mounted) return;
    setState(() => currentUserId = saved?.user.id ?? 0);
  }

  Future<void> _loadList() async {
    setState(() => loading = true);
    try {
      final result = await service.tasks(
        status: status,
        search: searchController.text,
      );
      tasks = result.tasks;
      stats = result.stats;
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadDetails({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    try {
      task = await service.show(widget.taskId!);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted && !silent) setState(() => loading = false);
      if (mounted && silent) setState(() {});
    }
  }

  Future<void> _pickAndSendFiles() async {
    final paths = await _pickFiles();
    if (paths.isEmpty) return;
    await _sendMessage(files: paths);
  }

  Future<void> _openCameraAndSend() async {
    final result = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(),
      fullscreenDialog: true,
    );
    if (result?.path.isNotEmpty == true) {
      await _sendMessage(files: [result!.path]);
    }
  }

  Future<List<String>> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'zip',
        'rar',
        'mp3',
        'm4a',
        'ogg',
        'wav',
        'mp4',
        'mov',
        'webm',
      ],
    );
    return result?.files
            .map((file) => file.path)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList() ??
        [];
  }

  Future<void> _sendMessage({List<String> files = const []}) async {
    final text = messageController.text.trim();
    if (text.isEmpty && files.isEmpty) return;
    setState(() => sending = true);
    try {
      await service.sendMessage(id: widget.taskId!, body: text, files: files);
      messageController.clear();
      await _loadDetails(silent: true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (recording || sending) return;
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      _snack('صلاحية الميكروفون مطلوبة للتسجيل');
      return;
    }

    final directory = await getTemporaryDirectory();
    recordingPath =
        '${directory.path}/app-development-${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await recorder.record(path: recordingPath!);
      recordingTimer?.cancel();
      if (!mounted) return;
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
      _snack('تعذر بدء التسجيل: $e');
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
      _snack('تعذر التحكم بالتسجيل: $e');
    }
  }

  Future<void> _finishRecording() async {
    if (!recording) return;
    recordingTimer?.cancel();
    try {
      final path = await recorder.stop() ?? recordingPath;
      if (mounted) {
        setState(() {
          recording = false;
          recordingPaused = false;
          recordingDuration = Duration.zero;
          recordingPath = null;
        });
      }
      if (path != null && path.isNotEmpty) {
        await _sendMessage(files: [path]);
      }
    } catch (e) {
      _snack('تعذر إرسال التسجيل: $e');
    }
  }

  Future<void> _cancelRecording() async {
    if (!recording) return;
    recordingTimer?.cancel();
    try {
      await recorder.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        recording = false;
        recordingPaused = false;
        recordingDuration = Duration.zero;
        recordingPath = null;
      });
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    final noteController = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          18.w,
          16.h,
          18.w,
          MediaQuery.of(context).viewInsets.bottom + 18.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تغيير الحالة', style: _titleStyle()),
            SizedBox(height: 12.h),
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'ملاحظة قصيرة اختيارية',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    try {
      await service.updateStatus(
        id: widget.taskId!,
        status: newStatus,
        note: noteController.text,
      );
      await _loadDetails(silent: true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _showCreateSheet({AppDevelopmentTask? parent}) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateTaskSheet(
        parent: parent,
        developers: developers,
        service: service,
        pickFiles: _pickFiles,
        onError: _snack,
      ),
    );

    if (created == true) {
      isDetails ? await _loadDetails(silent: true) : await _loadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تطوير التطبيق',
        action: false,
        actions: [
          if (!isDetails)
            IconButton(
              onPressed: _loadList,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      floatingActionButton: !isDetails
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(),
              child: const Icon(Icons.add),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : isDetails
              ? _detailsBody()
              : _listBody(),
    );
  }

  Widget _listBody() {
    return RefreshIndicator(
      onRefresh: _loadList,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 90.h),
        children: [
          _statsStrip(),
          SizedBox(height: 12.h),
          TextField(
            controller: searchController,
            onSubmitted: (_) => _loadList(),
            decoration: InputDecoration(
              hintText: 'بحث سريع',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _loadList,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses
                  .map((item) => Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: ChoiceChip(
                          selected: status == item.first,
                          label: Text(item.last),
                          onSelected: (_) {
                            setState(() => status = item.first);
                            _loadList();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: 12.h),
          if (tasks.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 60.h),
              child: const Center(child: Text('لا توجد مهام تطوير')),
            ),
          ...tasks.map(_taskCard),
        ],
      ),
    );
  }

  Widget _statsStrip() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: _softBox(),
      child: Row(
        children: [
          Expanded(child: _stat('الكل', stats['total'] ?? 0)),
          Expanded(child: _stat('قيد العمل', stats['in_progress'] ?? 0)),
          Expanded(child: _stat('منجزة', stats['done'] ?? 0)),
          SizedBox(
            width: 58.w,
            height: 58.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ((stats['progress_percent'] ?? 0) / 100).clamp(0, 1),
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade200,
                ),
                Center(
                  child: Text(
                    '${stats['progress_percent'] ?? 0}%',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: _titleStyle()),
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _taskCard(AppDevelopmentTask item) {
    return InkWell(
      onTap: () => Get.toNamed('/AppDevelopment/${item.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.r),
        decoration: _softBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(size: 15),
                  ),
                ),
                _pill(item.priorityLabel, _priorityColor(item.priority)),
              ],
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: item.progress / 100,
              minHeight: 6.h,
              borderRadius: BorderRadius.circular(8.r),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _pill(item.statusLabel, _statusColor(item.status)),
                SizedBox(width: 8.w),
                Text(
                  '${item.completedSubtasksCount}/${item.subtasksCount} فرعية',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  item.assigneeName,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsBody() {
    final current = task;
    if (current == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16.r),
            children: [
              _detailsHeader(current),
              SizedBox(height: 12.h),
              _statusActions(),
              SizedBox(height: 12.h),
              _subtasksSection(current),
              SizedBox(height: 12.h),
              _attachmentsSection(current.attachments),
              SizedBox(height: 12.h),
              Text('المحادثة', style: _titleStyle()),
              SizedBox(height: 8.h),
              ...current.messages.map(_messageBubble),
            ],
          ),
        ),
        _composer(),
      ],
    );
  }

  Widget _detailsHeader(AppDevelopmentTask item) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: _softBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: _titleStyle(size: 17))),
              _pill('${item.progress}%', AppColors.primaryColor),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(item.description, style: TextStyle(fontSize: 13.sp)),
          ],
          SizedBox(height: 10.h),
          LinearProgressIndicator(
            value: item.progress / 100,
            minHeight: 7.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _pill(item.statusLabel, _statusColor(item.status)),
              _pill(item.priorityLabel, _priorityColor(item.priority)),
              _pill('المبرمج: ${item.assigneeName}', Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusActions
            .map((item) => Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: OutlinedButton(
                    onPressed: () => _changeStatus(item.first),
                    child: Text(item.last),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _subtasksSection(AppDevelopmentTask item) {
    return Container(
      decoration: _softBox(),
      child: ExpansionTile(
        initiallyExpanded: item.subtasks.isNotEmpty,
        title: Text('المهام الفرعية', style: _titleStyle(size: 14)),
        subtitle: Text('${item.completedSubtasksCount}/${item.subtasksCount}'),
        trailing: IconButton(
          onPressed: () => _showCreateSheet(parent: item),
          icon: const Icon(Icons.add_task),
        ),
        children: item.subtasks.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: const Text('لا توجد مهام فرعية'),
                ),
              ]
            : item.subtasks
                .map(
                  (subtask) => ListTile(
                    dense: true,
                    title: Text(subtask.title),
                    subtitle: Text(subtask.statusLabel),
                    trailing: Text('${subtask.progress}%'),
                    onTap: () => Get.toNamed('/AppDevelopment/${subtask.id}'),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _attachmentsSection(List<AppDevelopmentAttachment> attachments) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: _softBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرفقات المهمة', style: _titleStyle(size: 13)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: attachments.map(_attachmentPreview).toList(),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(AppDevelopmentMessage message) {
    final mine = currentUserId > 0 && message.senderUserId == currentUserId;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: .86.sw),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xffdcf8c6)
              : (ThemeService.isDark.value
                  ? AppColors.customGreyColor4
                  : Colors.white),
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(12.r),
            topEnd: Radius.circular(12.r),
            bottomStart: Radius.circular(mine ? 12.r : 2.r),
            bottomEnd: Radius.circular(mine ? 2.r : 12.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine && message.senderName.isNotEmpty)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            if (message.body.isNotEmpty) ...[
              SizedBox(height: 5.h),
              Text(message.body, style: TextStyle(fontSize: 13.sp)),
            ],
            if (message.attachments.isNotEmpty) ...[
              SizedBox(height: 8.h),
              ...message.attachments.map(_attachmentMessageTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _attachmentPreview(AppDevelopmentAttachment attachment) {
    final type = attachment.displayType;
    if (type == 'image' && attachment.url.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openImage(attachment.url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            attachment.url,
            width: 86.w,
            height: 86.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _attachmentInfoRow(attachment),
          ),
        ),
      );
    }
    return _attachmentInfoRow(attachment);
  }

  Widget _attachmentMessageTile(AppDevelopmentAttachment attachment) {
    final type = attachment.displayType;
    if (type == 'audio' && attachment.url.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: _DevelopmentAudioAttachment(attachment: attachment),
      );
    }
    if (type == 'video' && attachment.url.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: _DevelopmentVideoAttachment(attachment: attachment),
      );
    }
    if (type == 'image' && attachment.url.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: GestureDetector(
          onTap: () => _openImage(attachment.url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.r),
            child: Image.network(
              attachment.url,
              width: 230.w,
              height: 170.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _attachmentInfoRow(attachment),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: _attachmentInfoRow(attachment),
    );
  }

  Widget _attachmentInfoRow(AppDevelopmentAttachment attachment) {
    return InkWell(
      onTap: () => _openAttachment(attachment),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        constraints: BoxConstraints(maxWidth: 250.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_attachmentIcon(attachment.displayType), size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                attachment.name.isEmpty
                    ? _attachmentLabel(attachment.displayType)
                    : attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(color: Colors.grey.withValues(alpha: .16))),
        ),
        child: recording
            ? _recordingBar()
            : Row(
                children: [
                  IconButton(
                    onPressed: sending ? null : _showAttachmentSheet,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليق',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: .08),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: sending ? null : _startRecording,
                    icon: const Icon(Icons.mic_none),
                  ),
                  IconButton.filled(
                    onPressed: sending ? null : _sendMessage,
                    icon: sending
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _recordingBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _cancelRecording,
          icon: const Icon(Icons.delete_outline, color: AppColors.redColor),
        ),
        Icon(Icons.fiber_manual_record, color: AppColors.redColor, size: 14.sp),
        SizedBox(width: 8.w),
        Text(
          _duration(recordingDuration),
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: AudioWaveforms(
            recorderController: recorder,
            size: Size(double.infinity, 38.h),
            waveStyle: const WaveStyle(
              waveColor: AppColors.primaryColor,
              extendWaveform: true,
              showMiddleLine: false,
            ),
          ),
        ),
        IconButton(
          onPressed: _toggleRecordingPause,
          icon: Icon(recordingPaused ? Icons.play_arrow : Icons.pause),
        ),
        IconButton.filled(
          onPressed: _finishRecording,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }

  Future<void> _showAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('كاميرا'),
              subtitle: const Text('تصوير صورة أو تسجيل فيديو'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openCameraAndSend();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('ملفات ووسائط'),
              subtitle: const Text('صور، فيديو، صوت، مستندات'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndSendFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(AppDevelopmentAttachment attachment) async {
    if (attachment.displayType == 'image' && attachment.url.isNotEmpty) {
      _openImage(attachment.url);
      return;
    }
    final uri = Uri.tryParse(attachment.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(12.w),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            PositionedDirectional(
              top: 8.h,
              end: 8.w,
              child: IconButton.filled(
                onPressed: Get.back,
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _softBox() {
    return BoxDecoration(
      color:
          ThemeService.isDark.value ? AppColors.customGreyColor4 : Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: Colors.grey.withValues(alpha: .14)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .035),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  TextStyle _titleStyle({double size = 16}) {
    return TextStyle(fontSize: size.sp, fontWeight: FontWeight.w800);
  }

  Color _statusColor(String status) {
    return {
          'new': Colors.blueGrey,
          'review': Colors.indigo,
          'in_progress': AppColors.primaryColor,
          'waiting_owner': Colors.orange,
          'done': Colors.green,
          'closed': Colors.teal,
          'canceled': Colors.red,
        }[status] ??
        Colors.blueGrey;
  }

  Color _priorityColor(String priority) {
    return {
          'low': Colors.blueGrey,
          'normal': Colors.teal,
          'high': Colors.orange,
          'urgent': Colors.red,
        }[priority] ??
        Colors.teal;
  }

  IconData _attachmentIcon(String type) {
    return {
          'image': Icons.image,
          'video': Icons.videocam,
          'audio': Icons.mic,
        }[type] ??
        Icons.insert_drive_file;
  }

  String _attachmentLabel(String type) {
    return {
          'image': 'صورة',
          'video': 'فيديو',
          'audio': 'تسجيل صوتي',
        }[type] ??
        'ملف';
  }

  String _duration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _snack(String message) {
    Get.snackbar('تطوير التطبيق', message, snackPosition: SnackPosition.BOTTOM);
  }
}

class _DevelopmentAudioAttachment extends StatefulWidget {
  const _DevelopmentAudioAttachment({required this.attachment});

  final AppDevelopmentAttachment attachment;

  @override
  State<_DevelopmentAudioAttachment> createState() =>
      _DevelopmentAudioAttachmentState();
}

class _DevelopmentAudioAttachmentState
    extends State<_DevelopmentAudioAttachment> {
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
      await player.setUrl(widget.attachment.url);
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
      return SizedBox(
        width: 230.w,
        height: 48.h,
        child: const Center(child: LinearProgressIndicator()),
      );
    }
    if (error != null) return const Text('تعذر تحميل التسجيل الصوتي');

    return Container(
      width: 255.w,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(10.r),
      ),
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
                onPressed: () async {
                  if (completed) await player.seek(Duration.zero);
                  playing ? await player.pause() : await player.play();
                },
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snapshot) {
                final duration = player.duration ?? Duration.zero;
                final position = snapshot.data ?? Duration.zero;
                final progress = duration.inMilliseconds == 0
                    ? 0.0
                    : (position.inMilliseconds / duration.inMilliseconds)
                        .clamp(0.0, 1.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: progress),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDuration(duration),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _DevelopmentVideoAttachment extends StatefulWidget {
  const _DevelopmentVideoAttachment({required this.attachment});

  final AppDevelopmentAttachment attachment;

  @override
  State<_DevelopmentVideoAttachment> createState() =>
      _DevelopmentVideoAttachmentState();
}

class _DevelopmentVideoAttachmentState
    extends State<_DevelopmentVideoAttachment> {
  VideoPlayerController? video;
  Object? error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.attachment.url));
      await controller.initialize();
      controller.addListener(_refresh);
      video = controller;
    } catch (e) {
      error = e;
    }
    if (mounted) setState(() {});
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    video?.removeListener(_refresh);
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const SizedBox(
        height: 130,
        child: Center(child: Text('تعذر تحميل الفيديو')),
      );
    }
    final controller = video;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        width: 230.w,
        height: 130.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () =>
          controller.value.isPlaying ? controller.pause() : controller.play(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.r),
        child: SizedBox(
          width: 240.w,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (!controller.value.isPlaying)
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black54,
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 34),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({
    required this.parent,
    required this.developers,
    required this.service,
    required this.pickFiles,
    required this.onError,
  });

  final AppDevelopmentTask? parent;
  final List<AppDevelopmentAdmin> developers;
  final AppDevelopmentService service;
  final Future<List<String>> Function() pickFiles;
  final void Function(String message) onError;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String priority = 'normal';
  late int developerId;
  List<String> files = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    developerId = widget.parent?.assignedToUserId ??
        (widget.developers.isNotEmpty ? widget.developers.first.id : 0);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = await widget.pickFiles();
    if (!mounted) return;
    setState(() => files = picked);
  }

  Future<void> _save() async {
    if (titleController.text.trim().isEmpty) {
      widget.onError('اكتب عنوان المهمة');
      return;
    }
    if (developerId == 0 || saving) return;

    setState(() => saving = true);
    try {
      await widget.service.create(
        parentId: widget.parent?.id,
        developerId: developerId,
        title: titleController.text,
        description: descriptionController.text,
        priority: priority,
        files: files,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18.w,
        14.h,
        18.w,
        MediaQuery.of(context).viewInsets.bottom + 18.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.parent == null ? 'مهمة تطوير جديدة' : 'مهمة فرعية',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.h),
            if (widget.developers.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue:
                    developerId == 0 ? widget.developers.first.id : developerId,
                decoration: const InputDecoration(
                  labelText: 'المبرمج',
                  border: OutlineInputBorder(),
                ),
                items: widget.developers
                    .map(
                      (developer) => DropdownMenuItem(
                        value: developer.id,
                        child: Text(developer.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) developerId = value;
                },
              ),
            SizedBox(height: 10.h),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(
                labelText: 'الأولوية',
                border: OutlineInputBorder(),
              ),
              items: _AppDevelopmentPriorities.items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.first,
                      child: Text(item.last),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) priority = value;
              },
            ),
            SizedBox(height: 10.h),
            OutlinedButton.icon(
              onPressed: saving ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: Text(files.isEmpty
                  ? 'إرفاق صور أو صوت أو فيديو'
                  : 'مرفقات: ${files.length}'),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: developerId == 0 || saving ? null : _save,
              child: saving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ المهمة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDevelopmentPriorities {
  static const items = [
    ['low', 'منخفضة'],
    ['normal', 'عادية'],
    ['high', 'عالية'],
    ['urgent', 'عاجلة'],
  ];
}
