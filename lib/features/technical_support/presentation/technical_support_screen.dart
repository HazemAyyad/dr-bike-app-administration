import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/initial_bindings.dart';
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

  bool loading = true;
  bool sending = false;
  bool canManageSupport = false;
  String status = 'all';
  List<SupportConversation> conversations = [];
  SupportConversation? conversation;
  List<SupportMessage> messages = [];
  Timer? poller;

  static const pageColor = Color(0xffeef0f2);
  static const cardColor = Color(0xfff7f8f9);
  static const borderColor = Color(0xffd2d7dd);
  static const actionColor = Color(0xff3f4a54);
  static const mutedColor = Color(0xff6b747d);

  bool get inConversation => widget.conversationId != null;

  @override
  void initState() {
    super.initState();
    inConversation ? _loadConversation() : _loadList();
    if (inConversation) {
      poller = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!sending) _loadConversation(silent: true);
      });
    }
  }

  @override
  void dispose() {
    poller?.cancel();
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
          ? const Center(child: CircularProgressIndicator())
          : inConversation
              ? _conversationBody()
              : _listBody(),
    );
  }

  Widget _listBody() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                  ),
                  onSubmitted: (_) => _loadList(),
                ),
              ),
              SizedBox(width: 8.w),
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                  DropdownMenuItem(value: 'pending', child: Text('متابعة')),
                  DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => status = value);
                  _loadList();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: conversations.isEmpty
              ? const Center(child: Text('لا توجد محادثات دعم'))
              : RefreshIndicator(
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
      onTap: () => Get.toNamed('/TechnicalSupport/${item.id}'),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
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
                  Text(
                    item.subject.isEmpty ? 'طلب دعم فني' : item.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    item.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedColor),
                  ),
                  if (canManageSupport && item.employeeName.isNotEmpty)
                    Text(item.employeeName,
                        style: TextStyle(fontSize: 11.sp, color: mutedColor)),
                ],
              ),
            ),
            if (unread > 0)
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
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.subject.isEmpty ? 'طلب دعم فني' : item.subject,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canManageSupport)
                  DropdownButton<String>(
                    value: item.status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                      DropdownMenuItem(value: 'pending', child: Text('متابعة')),
                      DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                    ],
                    onChanged: (value) {
                      if (value != null) _changeStatus(value);
                    },
                  )
                else
                  Text(_statusLabel(item.status)),
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
                    messages[index].senderType == 'employee' &&
                        userType == 'employee',
                  ),
                ),
        ),
        _composer(),
      ],
    );
  }

  Widget _messageBubble(SupportMessage message, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.78),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: mine ? const Color(0xffdfe8ef) : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.senderName.isNotEmpty)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: mutedColor,
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
            Text(
              message.createdAt == null
                  ? ''
                  : dateFormat.format(message.createdAt!),
              style: TextStyle(fontSize: 10.sp, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentTile(SupportAttachment attachment) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(attachment.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 4.h),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xffedf0f3),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_attachmentIcon(attachment.type), size: 18.sp),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                attachment.originalName.isEmpty
                    ? _attachmentLabel(attachment.type)
                    : attachment.originalName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    final disabled = conversation?.status == 'closed';
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.all(8.w),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              tooltip: 'مرفق',
              onPressed: disabled || sending ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                enabled: !disabled && !sending,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: actionColor),
              onPressed: disabled || sending ? null : () => _sendMessage(),
              icon: sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
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
            color: pageColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'عنوان اختياري',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: messageController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل طلب الدعم',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
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
