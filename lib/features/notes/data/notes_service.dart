import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../../core/databases/api/dio_consumer.dart';
import '../../../core/databases/api/end_points.dart';

class NoteUser {
  final int id;
  final String name;
  final String type;
  final String jobTitle;
  final String imageUrl;

  const NoteUser({
    required this.id,
    required this.name,
    required this.type,
    required this.jobTitle,
    required this.imageUrl,
  });

  factory NoteUser.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : const <String, dynamic>{};
    return NoteUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      jobTitle: employee['job_title']?.toString() ?? '',
      imageUrl: _firstImage(employee['employee_img']),
    );
  }
}

class NoteAttachment {
  final int id;
  final String type;
  final String url;
  final String originalName;
  final String mimeType;

  const NoteAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.originalName,
    required this.mimeType,
  });

  factory NoteAttachment.fromJson(Map<String, dynamic> json) => NoteAttachment(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        type: json['type']?.toString() ?? 'file',
        url: json['url']?.toString() ?? '',
        originalName: json['original_name']?.toString() ?? '',
        mimeType: json['mime_type']?.toString() ?? '',
      );
}

class NoteCollaborator {
  final int userId;
  final String permission;
  final NoteUser? user;

  const NoteCollaborator({
    required this.userId,
    required this.permission,
    this.user,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'permission': permission,
      };

  factory NoteCollaborator.fromJson(Map<String, dynamic> json) =>
      NoteCollaborator(
        userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
        permission: json['permission']?.toString() ?? 'view',
        user: json['user'] is Map
            ? NoteUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
            : null,
      );
}

class NoteItem {
  final int id;
  final String title;
  final String plainText;
  final String color;
  final List<String> labels;
  final String visibility;
  final String myPermission;
  final bool isPinned;
  final bool isArchived;
  final bool canEdit;
  final bool canManageSharing;
  final int attachmentsCount;
  final NoteUser? owner;
  final List<Map<String, dynamic>> bodyJson;
  final List<NoteAttachment> attachments;
  final List<NoteCollaborator> collaborators;
  final DateTime? reminderAt;
  final String reminderLabel;
  final DateTime? updatedAt;

  const NoteItem({
    required this.id,
    required this.title,
    required this.plainText,
    required this.color,
    required this.labels,
    required this.visibility,
    required this.myPermission,
    required this.isPinned,
    required this.isArchived,
    required this.canEdit,
    required this.canManageSharing,
    required this.attachmentsCount,
    required this.owner,
    required this.bodyJson,
    required this.attachments,
    required this.collaborators,
    required this.reminderAt,
    required this.reminderLabel,
    required this.updatedAt,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        title: json['title']?.toString() ?? '',
        plainText: json['plain_text']?.toString() ?? '',
        color: json['color']?.toString() ?? '',
        labels: (json['labels'] is List ? json['labels'] as List : const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        visibility: json['visibility']?.toString() ?? 'private',
        myPermission: json['my_permission']?.toString() ?? 'view',
        isPinned: json['is_pinned'] == true,
        isArchived: json['is_archived'] == true,
        canEdit: json['can_edit'] == true,
        canManageSharing: json['can_manage_sharing'] == true,
        attachmentsCount:
            int.tryParse(json['attachments_count']?.toString() ?? '') ?? 0,
        owner: json['owner'] is Map
            ? NoteUser.fromJson(Map<String, dynamic>.from(json['owner'] as Map))
            : null,
        bodyJson:
            (json['body_json'] is List ? json['body_json'] as List : const [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        attachments: (json['attachments'] is List
                ? json['attachments'] as List
                : const [])
            .whereType<Map>()
            .map((e) => NoteAttachment.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id > 0)
            .toList(),
        collaborators: (json['collaborators'] is List
                ? json['collaborators'] as List
                : const [])
            .whereType<Map>()
            .map((e) => NoteCollaborator.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.userId > 0)
            .toList(),
        reminderAt: DateTime.tryParse(json['reminder_at']?.toString() ?? ''),
        reminderLabel: json['reminder_label']?.toString() ?? '',
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      );
}

class NotesService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<List<NoteItem>> getNotes({
    String scope = 'active',
    String? search,
  }) async {
    final response = await _api.get(
      EndPoints.notes,
      queryParameters: {
        'scope': scope,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _extractList(response.data, const ['notes', 'data'])
        .whereType<Map>()
        .map((e) => NoteItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }

  Future<NoteItem> getNote(int id) async {
    final response = await _api.get(EndPoints.note(id));
    return NoteItem.fromJson(
      Map<String, dynamic>.from(response.data['note'] as Map),
    );
  }

  Future<NoteItem> saveNote({
    int? id,
    required String title,
    required List<Map<String, dynamic>> bodyJson,
    required String visibility,
    required String color,
    required List<String> labels,
    required bool isPinned,
    required bool isArchived,
    required List<NoteCollaborator> collaborators,
    DateTime? reminderAt,
    String? reminderLabel,
  }) async {
    final payload = {
      'title': title,
      'body_json': bodyJson,
      'visibility': visibility,
      'color': color.isEmpty ? null : color,
      'labels': labels,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'reminder_at': reminderAt?.toIso8601String(),
      'reminder_label': reminderLabel,
      'collaborators': collaborators.map((e) => e.toJson()).toList(),
    };
    final response = id == null
        ? await _api.post(EndPoints.notes, data: payload)
        : await _api.put(EndPoints.note(id), data: payload);
    return NoteItem.fromJson(
      Map<String, dynamic>.from(response.data['note'] as Map),
    );
  }

  Future<void> deleteNote(int id) async {
    await _api.delete(EndPoints.note(id));
  }

  Future<NoteAttachment> uploadAttachment(
    int noteId,
    String path, {
    String? type,
  }) async {
    final response = await _api.post(
      EndPoints.noteAttachments(noteId),
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
        if (type != null) 'attachment_type': type,
      }),
    );
    return NoteAttachment.fromJson(
      Map<String, dynamic>.from(response.data['attachment'] as Map),
    );
  }

  Future<void> deleteAttachment(int noteId, int attachmentId) async {
    await _api.delete('${EndPoints.noteAttachments(noteId)}/$attachmentId');
  }

  Future<List<NoteUser>> users({String? search}) async {
    final response = await _api.get(
      EndPoints.notesUsers,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data is Map ? response.data as Map : const {};
    return (data['users'] is List ? data['users'] as List : const [])
        .whereType<Map>()
        .map((e) => NoteUser.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }
}

List _extractList(dynamic raw, List<String> path) {
  dynamic current = raw;
  for (final key in path) {
    if (current is Map && current[key] != null) {
      current = current[key];
    }
  }
  return current is List ? current : const [];
}

String _firstImage(dynamic value) {
  if (value is List && value.isNotEmpty) return value.first?.toString() ?? '';
  if (value is String) return value;
  return '';
}
