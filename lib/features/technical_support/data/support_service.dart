import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../core/databases/api/dio_consumer.dart';
import '../../../core/databases/api/end_points.dart';

class SupportAttachment {
  final int id;
  final String type;
  final String url;
  final String path;
  final String originalName;
  final String mimeType;
  final int size;

  const SupportAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.path,
    required this.originalName,
    required this.mimeType,
    required this.size,
  });

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      SupportAttachment(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        type: json['type']?.toString() ?? 'document',
        url: json['url']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        originalName: json['original_name']?.toString() ?? '',
        mimeType: json['mime_type']?.toString() ?? '',
        size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      );
}

class SupportMessageReaction {
  final String reaction;
  final int count;
  final bool reacted;
  final List<String> users;

  const SupportMessageReaction({
    required this.reaction,
    required this.count,
    required this.reacted,
    required this.users,
  });

  factory SupportMessageReaction.fromJson(Map<String, dynamic> json) =>
      SupportMessageReaction(
        reaction: json['reaction']?.toString() ?? '',
        count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
        reacted: json['reacted'] == true,
        users: (json['users'] is List ? json['users'] as List : const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(),
      );
}

class SupportMessage {
  final int id;
  final int conversationId;
  final int senderUserId;
  final int senderEmployeeId;
  final String senderName;
  final String senderType;
  final String messageType;
  final String body;
  final List<SupportAttachment> attachments;
  final List<SupportMessageReaction> reactions;
  final String myReaction;
  final DateTime? createdAt;

  const SupportMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderEmployeeId,
    required this.senderName,
    required this.senderType,
    required this.messageType,
    required this.body,
    required this.attachments,
    required this.reactions,
    required this.myReaction,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        conversationId:
            int.tryParse(json['conversation_id']?.toString() ?? '') ?? 0,
        senderUserId:
            int.tryParse(json['sender_user_id']?.toString() ?? '') ?? 0,
        senderEmployeeId:
            int.tryParse(json['sender_employee_id']?.toString() ?? '') ?? 0,
        senderName: json['sender_name']?.toString() ?? '',
        senderType: json['sender_type']?.toString() ?? 'employee',
        messageType: json['message_type']?.toString() ?? 'text',
        body: json['body']?.toString() ?? '',
        attachments: (json['attachments'] is List
                ? json['attachments'] as List
                : const [])
            .whereType<Map>()
            .map(
                (e) => SupportAttachment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        reactions: (json['reactions'] is List
                ? json['reactions'] as List
                : const [])
            .whereType<Map>()
            .map((e) =>
                SupportMessageReaction.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.reaction.isNotEmpty && e.count > 0)
            .toList(),
        myReaction: json['my_reaction']?.toString() ?? '',
        createdAt: _parseDate(json['created_at']),
      );
}

class SupportConversation {
  final int id;
  final int employeeId;
  final String employeeName;
  final String subject;
  final String status;
  final String priority;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int employeeUnreadCount;
  final int supportUnreadCount;
  final int messagesCount;
  final int employeeSuggestionId;
  final String suggestionTitle;
  final DateTime? createdAt;

  const SupportConversation({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.subject,
    required this.status,
    required this.priority,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.employeeUnreadCount,
    required this.supportUnreadCount,
    required this.messagesCount,
    required this.employeeSuggestionId,
    required this.suggestionTitle,
    required this.createdAt,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) =>
      SupportConversation(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        employeeId: int.tryParse(json['employee_id']?.toString() ?? '') ?? 0,
        employeeName: json['employee_name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        priority: json['priority']?.toString() ?? 'normal',
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: _parseDate(json['last_message_at']),
        employeeUnreadCount:
            int.tryParse(json['employee_unread_count']?.toString() ?? '') ?? 0,
        supportUnreadCount:
            int.tryParse(json['support_unread_count']?.toString() ?? '') ?? 0,
        messagesCount:
            int.tryParse(json['messages_count']?.toString() ?? '') ?? 0,
        employeeSuggestionId:
            int.tryParse(json['employee_suggestion_id']?.toString() ?? '') ?? 0,
        suggestionTitle: json['suggestion_title']?.toString() ?? '',
        createdAt: _parseDate(json['created_at']),
      );
}

class SupportConversationListResult {
  final bool canManage;
  final List<SupportConversation> items;

  const SupportConversationListResult({
    required this.canManage,
    required this.items,
  });
}

class SupportConversationDetailResult {
  final bool canManage;
  final SupportConversation conversation;
  final List<SupportMessage> messages;

  const SupportConversationDetailResult({
    required this.canManage,
    required this.conversation,
    required this.messages,
  });
}

class SupportService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<SupportConversationListResult> getConversations({
    String? status,
    String? search,
  }) async {
    final response = await _api.get(
      EndPoints.supportConversations,
      queryParameters: {
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final raw = response.data;
    final canManage = raw is Map && raw['can_manage_support'] == true;
    final list = _extractList(raw, const ['conversations', 'data']);
    return SupportConversationListResult(
      canManage: canManage,
      items: list
          .whereType<Map>()
          .map(
              (e) => SupportConversation.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id > 0)
          .toList(),
    );
  }

  Future<SupportConversationDetailResult> getConversation(int id) async {
    final response = await _api.get(EndPoints.supportConversation(id));
    final raw = response.data as Map;
    final messages = _extractList(raw, const ['messages', 'data'])
        .whereType<Map>()
        .map((e) => SupportMessage.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList()
        .reversed
        .toList();

    return SupportConversationDetailResult(
      canManage: raw['can_manage_support'] == true,
      conversation: SupportConversation.fromJson(
        Map<String, dynamic>.from(raw['conversation'] as Map),
      ),
      messages: messages,
    );
  }

  Future<SupportConversation> createConversation({
    required String subject,
    required String message,
    List<String> files = const [],
  }) async {
    final response = await _api.post(
      EndPoints.supportConversations,
      data: await _formData(message: message, subject: subject, files: files),
    );
    return SupportConversation.fromJson(
      Map<String, dynamic>.from(response.data['conversation'] as Map),
    );
  }

  Future<SupportMessage> sendMessage({
    required int conversationId,
    required String message,
    List<String> files = const [],
  }) async {
    final response = await _api.post(
      EndPoints.supportConversationMessages(conversationId),
      data: await _formData(message: message, files: files),
    );
    return SupportMessage.fromJson(
      Map<String, dynamic>.from(response.data['support_message'] as Map),
    );
  }

  Future<void> markRead(int id) async {
    await _api.post(EndPoints.supportConversationRead(id));
  }

  Future<void> updateStatus(int id, String status) async {
    await _api
        .put(EndPoints.supportConversationStatus(id), data: {'status': status});
  }

  Future<SupportMessage> reactToMessage({
    required int conversationId,
    required int messageId,
    String? reaction,
  }) async {
    final response = await _api.post(
      EndPoints.supportMessageReaction(conversationId, messageId),
      data: {'reaction': reaction},
    );
    return SupportMessage.fromJson(
      Map<String, dynamic>.from(response.data['support_message'] as Map),
    );
  }

  Future<FormData> _formData({
    required String message,
    String? subject,
    List<String> files = const [],
  }) async {
    return FormData.fromMap({
      if (subject != null && subject.trim().isNotEmpty)
        'subject': subject.trim(),
      if (message.trim().isNotEmpty) 'message': message.trim(),
      for (var i = 0; i < files.length; i++)
        'attachments[$i]': await MultipartFile.fromFile(files[i]),
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

DateTime? _parseDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
