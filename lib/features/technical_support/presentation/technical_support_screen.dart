import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/initial_bindings.dart';
import '../../../core/utils/app_colors.dart';
import '../data/support_service.dart';

class TechnicalSupportScreen extends StatefulWidget {
  final int? conversationId;

  const TechnicalSupportScreen({Key? key, this.conversationId})
      : super(key: key);

  @override
  State<TechnicalSupportScreen> createState() => _TechnicalSupportScreenState();
}

class _TechnicalSupportScreenState extends State<TechnicalSupportScreen> {
  final service = SupportService();
  final searchController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final imagePicker = ImagePicker();
  late final RecorderController recorder;

  bool loading = true;
  bool sending = false;
  bool canManageSupport = false;
  bool recording = false;
  bool recordingPaused = false;
  Duration recordingDuration = Duration.zero;
  String status = 'all';
  String? recordingPath;
  List<SupportConversation> conversations = [];
  SupportConversation? conversation;
  List<SupportMessage> messages = [];
  Timer? poller;
  Timer? recordingTimer;

  static const pageColor = AppColors.operationalSurface;
  static const cardColor = Colors.white;
  static const borderColor = AppColors.operationalCardBorder;
  static const actionColor = AppColors.operationalPurple;
  static const mutedColor = Color(0xff6b7280);
  static const bubbleMine = Color(0xffeeeaff);
  static const composerColor = Color(0xfff8f7fc);

  bool get inConversation => widget.conversationId != null;

  @override
  void initState() {
    super.initState();
    recorder = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    inConversation ? _loadConversation() : _loadList();
    if (inConversation) {
      poller = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!sending && !recording) _loadConversation(silent: true);
      });
    }
  }

  @override
  void dispose() {
    poller?.cancel();
    recordingTimer?.cancel();
    recorder.dispose();
    searchController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() => loading = true);
    try {
      final result = await service.getConversations(
        status: status,
        search: searchController.text,
      );
      canManageSupport = result.canManage;
      conversations = result.items;
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadConversation({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    try {
      final result = await service.getConversation(widget.conversationId!);
      canManageSupport = result.canManage;
      conversation = result.conversation;
      messages = result.messages;
      await service.markRead(widget.conversationId!);
    } catch (e) {
      if (!silent) _message(e.toString());
    } finally {
      if (mounted && !silent) setState(() => loading = false);
      if (mounted && silent) setState(() {});
    }
  }

  Future<void> _createConversation() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();
    if (message.isEmpty) {
      _message('اكتب تفاصيل طلب الدعم');
      return;
    }

    setState(() => sending = true);
    try {
      final created = await service.createConversation(
        subject: subject,
        message: message,
      );
      subjectController.clear();
      messageController.clear();
      if (mounted) Navigator.pop(context);
      Get.toNamed('/TechnicalSupport/${created.id}');
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _sendMessage({List<String> files = const []}) async {
    final text = messageController.text.trim();
    if (text.isEmpty && files.isEmpty) return;

    setState(() => sending = true);
    try {
      await service.sendMessage(
        conversationId: widget.conversationId!,
        message: text,
        files: files,
      );
      messageController.clear();
      await _loadConversation(silent: true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _pickFiles() async {
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
        'mp3',
        'm4a',
        'ogg',
        'wav',
        'mp4',
        'mov',
        'webm',
      ],
    );
    final paths = result?.files
            .map((file) => file.path)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList() ??
        const [];
    if (paths.isNotEmpty) await _sendMessage(files: paths);
  }

  Future<void> _pickImage({required bool camera}) async {
    final picked = await imagePicker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked != null) await _sendMessage(files: [picked.path]);
  }

  Future<void> _pickVideo({required bool camera}) async {
    final picked = await imagePicker.pickVideo(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (picked != null) await _sendMessage(files: [picked.path]);
  }

  Future<void> _startRecording() async {
    if (recording || sending || conversation?.status == 'closed') return;
    var permission = await Permission.microphone.status;
    if (!permission.isGranted) {
      permission = await Permission.microphone.request();
    }
    if (!permission.isGranted) {
      _message('يجب السماح باستخدام الميكروفون لتسجيل رسالة صوتية');
      return;
    }

    final directory = await getTemporaryDirectory();
    recordingPath =
        '${directory.path}/support_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
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

  Future<void> _stopAndSendRecording() async {
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
      if (path == null || !await File(path).exists()) return;
      await _sendMessage(files: [path]);
    } catch (e) {
      if (mounted) {
        setState(() {
          recording = false;
          recordingPaused = false;
          recordingDuration = Duration.zero;
          recordingPath = null;
        });
      }
      _message('تعذر إرسال التسجيل: $e');
    }
  }

  Future<void> _changeStatus(String value) async {
    if (conversation == null) return;
    try {
      await service.updateStatus(conversation!.id, value);
      await _loadConversation();
    } catch (e) {
      _message(e.toString());
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(inConversation ? 'الدعم الفني' : 'محادثات الدعم الفني'),
        backgroundColor: actionColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: inConversation ? _loadConversation : _loadList,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: inConversation || canManageSupport
          ? null
          : FloatingActionButton(
              backgroundColor: actionColor,
              onPressed: _openCreateSheet,
              child: const Icon(Icons.add_comment, color: Colors.white),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: actionColor))
          : inConversation
              ? _conversationBody()
              : _listBody(),
    );
  }

  Widget _listBody() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث',
                    prefixIcon: const Icon(Icons.search, color: actionColor),
                    filled: true,
                    fillColor: pageColor,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: actionColor),
                    ),
                  ),
                  onSubmitted: (_) => _loadList(),
                ),
              ),
              SizedBox(width: 8.w),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: pageColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: borderColor),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('الكل')),
                        DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('متابعة')),
                        DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => status = value);
                        _loadList();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: conversations.isEmpty
              ? const Center(child: Text('لا توجد محادثات دعم'))
              : RefreshIndicator(
                  color: actionColor,
                  onRefresh: _loadList,
                  child: ListView.separated(
                    padding: EdgeInsets.all(10.w),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) =>
                        _conversationCard(conversations[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _conversationCard(SupportConversation item) {
    final unread =
        canManageSupport ? item.supportUnreadCount : item.employeeUnreadCount;
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () => Get.toNamed('/TechnicalSupport/${item.id}'),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: actionColor,
              child: Text(
                item.employeeName.isNotEmpty ? item.employeeName[0] : 'د',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.subject.isEmpty ? 'طلب دعم فني' : item.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusChip(item.status),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    item.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedColor),
                  ),
                  if (canManageSupport && item.employeeName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        item.employeeName,
                        style: TextStyle(fontSize: 11.sp, color: mutedColor),
                      ),
                    ),
                ],
              ),
            ),
            if (unread > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _conversationBody() {
    final item = conversation;
    return Column(
      children: [
        if (item != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: bubbleMine,
                  child: const Icon(Icons.support_agent, color: actionColor),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject.isEmpty ? 'طلب دعم فني' : item.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        canManageSupport && item.employeeName.isNotEmpty
                            ? item.employeeName
                            : _statusLabel(item.status),
                        style: TextStyle(fontSize: 11.sp, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                if (canManageSupport)
                  _supportStatusActions(item)
                else
                  _statusChip(item.status),
              ],
            ),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('لا توجد رسائل بعد'))
              : ListView.builder(
                  padding: EdgeInsets.all(10.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _messageBubble(
                    messages[index],
                    _isMine(messages[index]),
                  ),
                ),
        ),
        _composer(),
      ],
    );
  }

  Widget _supportStatusActions(SupportConversation item) {
    final closed = item.status == 'closed';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: pageColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: item.status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                  DropdownMenuItem(value: 'pending', child: Text('متابعة')),
                  DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                ],
                onChanged: (value) {
                  if (value != null) _changeStatus(value);
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        IconButton.filledTonal(
          tooltip: closed ? 'إعادة فتح المحادثة' : 'إغلاق المحادثة',
          style: IconButton.styleFrom(
            backgroundColor:
                closed ? Colors.orange.shade50 : Colors.green.shade50,
            foregroundColor:
                closed ? Colors.orange.shade800 : Colors.green.shade800,
          ),
          onPressed:
              sending ? null : () => _changeStatus(closed ? 'open' : 'closed'),
          icon: Icon(closed ? Icons.lock_open : Icons.check_circle_outline),
        ),
      ],
    );
  }

  bool _isMine(SupportMessage message) {
    if (userType == 'employee') return message.senderType == 'employee';
    return message.senderType != 'employee';
  }

  Widget _messageBubble(SupportMessage message, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.8),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: mine ? bubbleMine : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.r),
            topRight: Radius.circular(10.r),
            bottomLeft: Radius.circular(mine ? 10.r : 2.r),
            bottomRight: Radius.circular(mine ? 2.r : 10.r),
          ),
          border: Border.all(color: mine ? bubbleMine : borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.senderName.isNotEmpty)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: mine ? actionColor : mutedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (message.body.isNotEmpty) ...[
              SizedBox(height: 3.h),
              Text(message.body, style: TextStyle(fontSize: 14.sp)),
            ],
            if (message.attachments.isNotEmpty) ...[
              SizedBox(height: 8.h),
              ...message.attachments.map(_attachmentTile),
            ],
            SizedBox(height: 5.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                message.createdAt == null
                    ? ''
                    : dateFormat.format(message.createdAt!),
                style: TextStyle(fontSize: 10.sp, color: mutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentTile(SupportAttachment attachment) {
    if (attachment.type == 'audio' && attachment.url.isNotEmpty) {
      return SupportAudioBubble(attachment: attachment);
    }
    if (attachment.type == 'video' && attachment.url.isNotEmpty) {
      return SupportVideoBubble(attachment: attachment);
    }

    final isImage = attachment.type == 'image' && attachment.url.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () => _openAttachment(attachment),
      child: Container(
        margin: EdgeInsets.only(top: 4.h),
        constraints: BoxConstraints(maxWidth: Get.width * 0.66),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
        ),
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  attachment.url,
                  width: Get.width * 0.58,
                  height: 150.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _attachmentInfoRow(attachment),
                ),
              )
            : _attachmentInfoRow(attachment),
      ),
    );
  }

  Widget _attachmentInfoRow(SupportAttachment attachment) {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: bubbleMine,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _attachmentIcon(attachment.type),
              size: 19.sp,
              color: actionColor,
            ),
          ),
          SizedBox(width: 7.w),
          Flexible(
            child: Text(
              attachment.originalName.isEmpty
                  ? _attachmentLabel(attachment.type)
                  : attachment.originalName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(SupportAttachment attachment) async {
    if (attachment.type == 'image' && attachment.url.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: EdgeInsets.all(12.w),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Image.network(attachment.url, fit: BoxFit.contain),
              ),
              PositionedDirectional(
                top: 6.h,
                end: 6.w,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(attachment.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _composer() {
    final disabled = conversation?.status == 'closed';
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 7.h, 8.w, 8.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: recording
            ? _recordingBar()
            : Row(
                children: [
                  IconButton(
                    tooltip: 'مرفقات',
                    onPressed: disabled || sending ? null : _openAttachSheet,
                    icon: const Icon(Icons.add_circle_outline,
                        color: actionColor),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      enabled: !disabled && !sending,
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: disabled ? 'المحادثة مغلقة' : 'اكتب رسالة',
                        filled: true,
                        fillColor: composerColor,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: actionColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  _sendOrRecordButton(disabled),
                ],
              ),
      ),
    );
  }

  Widget _sendOrRecordButton(bool disabled) {
    final hasText = messageController.text.trim().isNotEmpty;
    return IconButton.filled(
      style: IconButton.styleFrom(backgroundColor: actionColor),
      onPressed: disabled || sending
          ? null
          : hasText
              ? () => _sendMessage()
              : _startRecording,
      icon: sending
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
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
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: composerColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record,
                    size: 13.sp, color: Colors.red.shade700),
                SizedBox(width: 7.w),
                Text(
                  _duration(recordingDuration),
                  style: const TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: AudioWaveforms(
                    size: Size(double.infinity, 30.h),
                    recorderController: recorder,
                    waveStyle: WaveStyle(
                      waveColor: actionColor.withValues(alpha: 0.75),
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: recordingPaused ? 'متابعة' : 'إيقاف مؤقت',
                  onPressed: _toggleRecordingPause,
                  icon: Icon(recordingPaused ? Icons.play_arrow : Icons.pause),
                  color: actionColor,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 6.w),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: actionColor),
          onPressed: sending ? null : _stopAndSendRecording,
          icon: const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }

  void _openAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _attachAction(
                    icon: Icons.photo_library_outlined,
                    label: 'صورة',
                    onTap: () => _closeSheetAndRun(
                      () => _pickImage(camera: false),
                    ),
                  ),
                ),
                Expanded(
                  child: _attachAction(
                    icon: Icons.photo_camera_outlined,
                    label: 'تصوير',
                    onTap: () => _closeSheetAndRun(
                      () => _pickImage(camera: true),
                    ),
                  ),
                ),
                Expanded(
                  child: _attachAction(
                    icon: Icons.video_library_outlined,
                    label: 'فيديو',
                    onTap: () => _closeSheetAndRun(
                      () => _pickVideo(camera: false),
                    ),
                  ),
                ),
                Expanded(
                  child: _attachAction(
                    icon: Icons.videocam_outlined,
                    label: 'تصوير فيديو',
                    onTap: () => _closeSheetAndRun(
                      () => _pickVideo(camera: true),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: actionColor,
                  side: const BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => _closeSheetAndRun(_pickFiles),
                icon: const Icon(Icons.attach_file),
                label: const Text('ملف أو مستند'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: bubbleMine,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: actionColor),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _closeSheetAndRun(Future<void> Function() action) {
    Navigator.pop(context);
    action();
  }

  void _openCreateSheet() {
    subjectController.clear();
    messageController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'فتح محادثة دعم',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: subjectController,
                decoration: _sheetInputDecoration('عنوان اختياري'),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: messageController,
                minLines: 4,
                maxLines: 8,
                decoration: _sheetInputDecoration('تفاصيل طلب الدعم'),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: sending ? null : _createConversation,
                  icon: const Icon(Icons.add_comment),
                  label: Text(sending ? 'جارٍ الإرسال...' : 'فتح محادثة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: pageColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: actionColor),
      ),
    );
  }

  Widget _statusChip(String value) {
    final isClosed = value == 'closed';
    final isPending = value == 'pending';
    final color = isClosed
        ? Colors.red.shade700
        : isPending
            ? Colors.orange.shade800
            : actionColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(value),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _duration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'closed':
        return 'مغلقة';
      case 'pending':
        return 'متابعة';
      default:
        return 'مفتوحة';
    }
  }

  IconData _attachmentIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _attachmentLabel(String type) {
    switch (type) {
      case 'image':
        return 'صورة';
      case 'video':
        return 'فيديو';
      case 'audio':
        return 'تسجيل صوتي';
      default:
        return 'ملف';
    }
  }
}

class SupportAudioBubble extends StatefulWidget {
  const SupportAudioBubble({Key? key, required this.attachment})
      : super(key: key);

  final SupportAttachment attachment;

  @override
  State<SupportAudioBubble> createState() => _SupportAudioBubbleState();
}

class _SupportAudioBubbleState extends State<SupportAudioBubble> {
  final ja.AudioPlayer player = ja.AudioPlayer();
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
      return Container(
        width: 240.w,
        height: 54.h,
        margin: EdgeInsets.only(top: 4.h),
        alignment: Alignment.center,
        child:
            const LinearProgressIndicator(color: AppColors.operationalPurple),
      );
    }
    if (error != null) {
      return _mediaError('تعذر تحميل التسجيل الصوتي');
    }

    return Container(
      width: 270.w,
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
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
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.operationalPurple,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.h,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: AppColors.operationalPurple,
                        inactiveTrackColor: AppColors.operationalCardBorder,
                        thumbColor: AppColors.operationalPurple,
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
                      '${_supportDuration(position)} / ${_supportDuration(duration)}',
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Icon(Icons.mic, color: AppColors.operationalPurple),
        ],
      ),
    );
  }
}

class SupportVideoBubble extends StatefulWidget {
  const SupportVideoBubble({Key? key, required this.attachment})
      : super(key: key);

  final SupportAttachment attachment;

  @override
  State<SupportVideoBubble> createState() => _SupportVideoBubbleState();
}

class _SupportVideoBubbleState extends State<SupportVideoBubble> {
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
    if (error != null) return _mediaError('تعذر تحميل الفيديو');
    final controller = video;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: 240.w,
        height: 140.h,
        margin: EdgeInsets.only(top: 4.h),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: AppColors.operationalPurple,
        ),
      );
    }

    return GestureDetector(
      onTap: () =>
          controller.value.isPlaying ? controller.pause() : controller.play(),
      child: Container(
        width: 250.w,
        margin: EdgeInsets.only(top: 4.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.operationalCardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              if (!controller.value.isPlaying)
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 34),
                ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.operationalPurple,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _mediaError(String text) {
  return Container(
    width: 230.w,
    margin: EdgeInsets.only(top: 4.h),
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: AppColors.operationalCardBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        SizedBox(width: 6.w),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

String _supportDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
