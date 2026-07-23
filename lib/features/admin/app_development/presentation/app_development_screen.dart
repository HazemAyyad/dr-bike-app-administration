import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/helpers/custom_app_bar.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
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

  bool loading = true;
  bool sending = false;
  String status = 'all';
  Map<String, int> stats = {};
  List<AppDevelopmentTask> tasks = [];
  List<AppDevelopmentAdmin> developers = [];
  AppDevelopmentTask? task;

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

  static const priorities = [
    ['low', 'منخفضة'],
    ['normal', 'عادية'],
    ['high', 'عالية'],
    ['urgent', 'عاجلة'],
  ];

  @override
  void initState() {
    super.initState();
    isDetails ? _loadDetails() : _loadList();
    _loadMetadata();
  }

  @override
  void dispose() {
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var priority = 'normal';
    var developerId = parent?.assignedToUserId ??
        (developers.isNotEmpty ? developers.first.id : 0);
    var files = <String>[];

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
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
                    parent == null ? 'مهمة تطوير جديدة' : 'مهمة فرعية',
                    style: _titleStyle(),
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
                  if (developers.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue:
                          developerId == 0 ? developers.first.id : developerId,
                      decoration: const InputDecoration(
                        labelText: 'المبرمج',
                        border: OutlineInputBorder(),
                      ),
                      items: developers
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
                    items: priorities
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
                    onPressed: () async {
                      final picked = await _pickFiles();
                      setSheetState(() => files = picked);
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(files.isEmpty
                        ? 'إرفاق صور أو صوت أو فيديو'
                        : 'مرفقات: ${files.length}'),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: developerId == 0
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              _snack('اكتب عنوان المهمة');
                              return;
                            }
                            try {
                              await service.create(
                                parentId: parent?.id,
                                developerId: developerId,
                                title: titleController.text,
                                description: descriptionController.text,
                                priority: priority,
                                files: files,
                              );
                              if (context.mounted) Navigator.pop(context, true);
                            } catch (e) {
                              _snack(e.toString());
                            }
                          },
                    child: const Text('حفظ المهمة'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    titleController.dispose();
    descriptionController.dispose();

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
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: attachments.map(_attachmentChip).toList(),
    );
  }

  Widget _messageBubble(AppDevelopmentMessage message) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.withValues(alpha: .16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderName, style: _titleStyle(size: 12)),
            if (message.body.isNotEmpty) ...[
              SizedBox(height: 5.h),
              Text(message.body),
            ],
            if (message.attachments.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: message.attachments.map(_attachmentChip).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _attachmentChip(AppDevelopmentAttachment attachment) {
    return ActionChip(
      avatar: Icon(_attachmentIcon(attachment.type), size: 18.sp),
      label: Text(
        attachment.name.isEmpty ? attachment.type : attachment.name,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: attachment.url.isEmpty
          ? null
          : () => launchUrl(Uri.parse(attachment.url),
              mode: LaunchMode.externalApplication),
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
        child: Row(
          children: [
            IconButton(
              onPressed: sending ? null : _pickAndSendFiles,
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب تعليق',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton.filled(
              onPressed: sending ? null : _sendMessage,
              icon: sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
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

  void _snack(String message) {
    Get.snackbar('تطوير التطبيق', message, snackPosition: SnackPosition.BOTTOM);
  }
}
