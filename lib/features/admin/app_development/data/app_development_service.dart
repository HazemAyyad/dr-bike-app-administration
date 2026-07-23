import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../../core/databases/api/dio_consumer.dart';
import '../../../../core/databases/api/end_points.dart';

class AppDevelopmentAdmin {
  final int id;
  final String name;
  final String role;

  const AppDevelopmentAdmin({
    required this.id,
    required this.name,
    required this.role,
  });

  factory AppDevelopmentAdmin.fromJson(Map<String, dynamic> json) {
    return AppDevelopmentAdmin(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['development_role']?.toString() ?? 'none',
    );
  }
}

class AppDevelopmentAttachment {
  final int id;
  final String url;
  final String name;
  final String type;
  final String mimeType;

  const AppDevelopmentAttachment({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
    required this.mimeType,
  });

  factory AppDevelopmentAttachment.fromJson(Map<String, dynamic> json) {
    return AppDevelopmentAttachment(
      id: int.tryParse('${json['id']}') ?? 0,
      url: json['url']?.toString() ?? '',
      name: json['original_name']?.toString() ?? '',
      type: json['attachment_type']?.toString() ?? 'document',
      mimeType: json['mime_type']?.toString() ?? '',
    );
  }

  String get displayType {
    final normalizedType = type.toLowerCase();
    final lowerName = name.toLowerCase();
    final lowerUrl = url.toLowerCase();
    final lowerMime = mimeType.toLowerCase();
    final source = '$lowerName $lowerUrl';

    if (normalizedType == 'audio' ||
        lowerMime.startsWith('audio/') ||
        source.endsWith('.m4a') ||
        source.endsWith('.mp3') ||
        source.endsWith('.aac') ||
        source.endsWith('.ogg') ||
        source.endsWith('.wav')) {
      return 'audio';
    }
    if (normalizedType == 'image' ||
        lowerMime.startsWith('image/') ||
        source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.png') ||
        source.endsWith('.webp') ||
        source.endsWith('.heic') ||
        source.endsWith('.heif')) {
      return 'image';
    }
    if (normalizedType == 'video' ||
        lowerMime.startsWith('video/') ||
        source.endsWith('.mp4') ||
        source.endsWith('.mov') ||
        source.endsWith('.webm') ||
        source.endsWith('.3gp') ||
        source.endsWith('.m4v') ||
        source.endsWith('.avi')) {
      return 'video';
    }

    return type;
  }
}

class AppDevelopmentMessage {
  final int id;
  final int senderUserId;
  final String senderName;
  final String body;
  final List<AppDevelopmentAttachment> attachments;
  final List<AppDevelopmentMessageReaction> reactions;
  final String myReaction;
  final DateTime? createdAt;

  const AppDevelopmentMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.body,
    required this.attachments,
    required this.reactions,
    required this.myReaction,
    this.createdAt,
  });

  factory AppDevelopmentMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] is Map
        ? Map<String, dynamic>.from(json['sender'] as Map)
        : <String, dynamic>{};
    return AppDevelopmentMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      senderUserId: int.tryParse('${json['sender_user_id']}') ?? 0,
      senderName: sender['name']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      attachments: _list(json['attachments'])
          .whereType<Map>()
          .map((e) => AppDevelopmentAttachment.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      reactions: _list(json['reactions'])
          .whereType<Map>()
          .map((e) => AppDevelopmentMessageReaction.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((e) => e.reaction.isNotEmpty && e.count > 0)
          .toList(),
      myReaction: json['my_reaction']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

class AppDevelopmentMessageReaction {
  final String reaction;
  final int count;
  final bool reacted;
  final List<String> users;

  const AppDevelopmentMessageReaction({
    required this.reaction,
    required this.count,
    required this.reacted,
    required this.users,
  });

  factory AppDevelopmentMessageReaction.fromJson(Map<String, dynamic> json) {
    return AppDevelopmentMessageReaction(
      reaction: json['reaction']?.toString() ?? '',
      count: int.tryParse('${json['count']}') ?? 0,
      reacted: json['reacted'] == true,
      users: _list(json['users'])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

class AppDevelopmentTask {
  final int id;
  final int parentId;
  final int assignedToUserId;
  final int createdByUserId;
  final String title;
  final String description;
  final String status;
  final String statusLabel;
  final String priority;
  final String priorityLabel;
  final int progress;
  final int subtasksCount;
  final int completedSubtasksCount;
  final int messagesCount;
  final String assigneeName;
  final String creatorName;
  final DateTime? updatedAt;
  final List<AppDevelopmentTask> subtasks;
  final List<AppDevelopmentMessage> messages;
  final List<AppDevelopmentAttachment> attachments;

  const AppDevelopmentTask({
    required this.id,
    required this.parentId,
    required this.assignedToUserId,
    required this.createdByUserId,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.priorityLabel,
    required this.progress,
    required this.subtasksCount,
    required this.completedSubtasksCount,
    required this.messagesCount,
    required this.assigneeName,
    required this.creatorName,
    this.updatedAt,
    this.subtasks = const [],
    this.messages = const [],
    this.attachments = const [],
  });

  factory AppDevelopmentTask.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'] is Map
        ? Map<String, dynamic>.from(json['assignee'] as Map)
        : <String, dynamic>{};
    final creator = json['creator'] is Map
        ? Map<String, dynamic>.from(json['creator'] as Map)
        : <String, dynamic>{};

    return AppDevelopmentTask(
      id: int.tryParse('${json['id']}') ?? 0,
      parentId: int.tryParse('${json['parent_id']}') ?? 0,
      assignedToUserId: int.tryParse('${json['assigned_to_user_id']}') ?? 0,
      createdByUserId: int.tryParse('${json['created_by_user_id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      statusLabel: json['status_label']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      priorityLabel: json['priority_label']?.toString() ?? '',
      progress: int.tryParse('${json['progress']}') ?? 0,
      subtasksCount: int.tryParse('${json['subtasks_count']}') ?? 0,
      completedSubtasksCount:
          int.tryParse('${json['completed_subtasks_count']}') ?? 0,
      messagesCount: int.tryParse('${json['messages_count']}') ?? 0,
      assigneeName: assignee['name']?.toString() ?? '',
      creatorName: creator['name']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal(),
      subtasks: _list(json['subtasks'])
          .whereType<Map>()
          .map((e) => AppDevelopmentTask.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      messages: _list(json['messages'])
          .whereType<Map>()
          .map((e) =>
              AppDevelopmentMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      attachments: _list(json['attachments'])
          .whereType<Map>()
          .map((e) => AppDevelopmentAttachment.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class AppDevelopmentListResult {
  final Map<String, int> stats;
  final List<AppDevelopmentTask> tasks;

  const AppDevelopmentListResult({
    required this.stats,
    required this.tasks,
  });
}

class AppDevelopmentService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<Map<String, List<AppDevelopmentAdmin>>> metadata() async {
    final response = await _api.get(EndPoints.appDevelopmentMetadata);
    final raw = Map<String, dynamic>.from(response.data as Map);
    return {
      'owners': _list(raw['owners'])
          .whereType<Map>()
          .map(
              (e) => AppDevelopmentAdmin.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      'developers': _list(raw['developers'])
          .whereType<Map>()
          .map(
              (e) => AppDevelopmentAdmin.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    };
  }

  Future<AppDevelopmentListResult> tasks({
    String status = 'all',
    String search = '',
  }) async {
    final response = await _api.get(
      EndPoints.appDevelopmentTasks,
      queryParameters: {
        if (status != 'all') 'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final raw = Map<String, dynamic>.from(response.data as Map);
    final statsRaw = raw['stats'] is Map
        ? Map<String, dynamic>.from(raw['stats'] as Map)
        : <String, dynamic>{};
    final tasks = _extractList(raw, const ['tasks', 'data'])
        .whereType<Map>()
        .map((e) => AppDevelopmentTask.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();

    return AppDevelopmentListResult(
      stats: statsRaw.map((key, value) => MapEntry(
            key,
            int.tryParse('$value') ?? 0,
          )),
      tasks: tasks,
    );
  }

  Future<AppDevelopmentTask> show(int id) async {
    final response = await _api.get(EndPoints.appDevelopmentTask(id));
    return AppDevelopmentTask.fromJson(
      Map<String, dynamic>.from(response.data['task'] as Map),
    );
  }

  Future<AppDevelopmentTask> create({
    int? parentId,
    required int developerId,
    required String title,
    required String description,
    required String priority,
    List<String> files = const [],
    List<String> attachmentTypes = const [],
  }) async {
    final response = await _api.post(
      EndPoints.appDevelopmentTasks,
      data: await _formData(
        parentId: parentId,
        developerId: developerId,
        title: title,
        description: description,
        priority: priority,
        files: files,
        attachmentTypes: attachmentTypes,
      ),
    );
    return AppDevelopmentTask.fromJson(
      Map<String, dynamic>.from(response.data['task'] as Map),
    );
  }

  Future<void> updateStatus({
    required int id,
    required String status,
    String? note,
  }) async {
    await _api.post(
      EndPoints.appDevelopmentTaskStatus(id),
      data: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<void> sendMessage({
    required int id,
    required String body,
    List<String> files = const [],
    List<String> attachmentTypes = const [],
  }) async {
    await _api.post(
      EndPoints.appDevelopmentTaskMessages(id),
      data: await _formData(
        message: body,
        files: files,
        attachmentTypes: attachmentTypes,
      ),
    );
  }

  Future<void> reactToMessage({
    required int taskId,
    required int messageId,
    String? reaction,
  }) async {
    await _api.post(
      EndPoints.appDevelopmentMessageReaction(taskId, messageId),
      data: {'reaction': reaction},
    );
  }

  Future<FormData> _formData({
    int? parentId,
    int? developerId,
    String? title,
    String? description,
    String? priority,
    String? message,
    List<String> files = const [],
    List<String> attachmentTypes = const [],
  }) async {
    return FormData.fromMap({
      if (parentId != null && parentId > 0) 'parent_id': parentId,
      if (developerId != null) 'assigned_to_user_id': developerId,
      if (title != null) 'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (priority != null) 'priority': priority,
      if (message != null && message.trim().isNotEmpty) 'body': message.trim(),
      for (var i = 0; i < files.length; i++)
        'attachments[$i]': await MultipartFile.fromFile(files[i]),
      for (var i = 0; i < attachmentTypes.length && i < files.length; i++)
        'attachment_types[$i]': attachmentTypes[i],
    });
  }

  List<dynamic> _extractList(dynamic raw, List<String> keys) {
    dynamic current = raw;
    for (final key in keys) {
      if (current is Map && current[key] != null) current = current[key];
    }
    if (current is List) return current;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];
