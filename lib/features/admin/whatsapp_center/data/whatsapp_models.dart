class WhatsAppDashboard {
  final int totalContacts,
      totalConversations,
      openConversations,
      unreadConversations,
      messagesToday,
      failedMessagesToday;
  const WhatsAppDashboard({
    required this.totalContacts,
    required this.totalConversations,
    required this.openConversations,
    required this.unreadConversations,
    required this.messagesToday,
    required this.failedMessagesToday,
  });
  factory WhatsAppDashboard.fromJson(Map<String, dynamic> j) =>
      WhatsAppDashboard(
        totalContacts: _int(j['total_contacts']),
        totalConversations: _int(j['total_conversations']),
        openConversations: _int(j['open_conversations']),
        unreadConversations: _int(j['unread_conversations']),
        messagesToday: _int(j['messages_today']),
        failedMessagesToday: _int(j['failed_messages_today']),
      );
}

class WhatsAppContact {
  final int id;
  final String? name;
  final String phone;
  const WhatsAppContact({required this.id, this.name, required this.phone});
  factory WhatsAppContact.fromJson(Map<String, dynamic> j) => WhatsAppContact(
      id: _int(j['id']),
      name: j['name']?.toString(),
      phone: j['phone']?.toString() ?? '');
}

class WhatsAppConversation {
  final int id, unreadCount;
  final String phone, status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final WhatsAppContact? contact;
  const WhatsAppConversation({
    required this.id,
    required this.phone,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.contact,
  });
  factory WhatsAppConversation.fromJson(Map<String, dynamic> j) =>
      WhatsAppConversation(
        id: _int(j['id']),
        phone: j['phone']?.toString() ?? '',
        status: j['status']?.toString() ?? 'open',
        lastMessage: j['last_message']?.toString(),
        lastMessageAt:
            DateTime.tryParse(j['last_message_at']?.toString() ?? ''),
        unreadCount: _int(j['unread_count']),
        contact: j['contact'] is Map
            ? WhatsAppContact.fromJson(
                Map<String, dynamic>.from(j['contact'] as Map))
            : null,
      );
}

class WhatsAppMessage {
  final int id;
  final String direction, type, status;
  final String? body, errorMessage;
  final DateTime? createdAt;
  const WhatsAppMessage({
    required this.id,
    required this.direction,
    required this.type,
    this.body,
    required this.status,
    this.errorMessage,
    this.createdAt,
  });
  factory WhatsAppMessage.fromJson(Map<String, dynamic> j) => WhatsAppMessage(
        id: _int(j['id']),
        direction: j['direction']?.toString() ?? 'inbound',
        type: j['message_type']?.toString() ?? 'text',
        body: j['body']?.toString(),
        status: j['status']?.toString() ?? 'pending',
        errorMessage: j['error_message']?.toString(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

class WhatsAppTemplate {
  final int id;
  final String name, language, body;
  final String? category;
  final List<dynamic> variables;
  final bool isActive;
  const WhatsAppTemplate({
    required this.id,
    required this.name,
    this.category,
    required this.language,
    required this.body,
    required this.variables,
    required this.isActive,
  });
  factory WhatsAppTemplate.fromJson(Map<String, dynamic> j) => WhatsAppTemplate(
        id: _int(j['id']),
        name: j['name']?.toString() ?? '',
        category: j['category']?.toString(),
        language: j['language']?.toString() ?? 'ar',
        body: j['body']?.toString() ?? '',
        variables: j['variables'] is List
            ? List<dynamic>.from(j['variables'])
            : const [],
        isActive: j['is_active'] == true || j['is_active'] == 1,
      );
}

class WhatsAppSettings {
  final bool configured;
  final String message;
  final String? phoneNumberId, businessAccountId;
  final Map<String, dynamic> values;
  const WhatsAppSettings({
    required this.configured,
    required this.message,
    this.phoneNumberId,
    this.businessAccountId,
    required this.values,
  });
  factory WhatsAppSettings.fromJson(Map<String, dynamic> j) {
    final c = j['connection'] is Map
        ? Map<String, dynamic>.from(j['connection'] as Map)
        : <String, dynamic>{};
    return WhatsAppSettings(
      configured: c['configured'] == true,
      message: c['message']?.toString() ?? '',
      phoneNumberId: c['phone_number_id']?.toString(),
      businessAccountId: c['business_account_id']?.toString(),
      values: j['settings'] is Map
          ? Map<String, dynamic>.from(j['settings'] as Map)
          : const {},
    );
  }
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
