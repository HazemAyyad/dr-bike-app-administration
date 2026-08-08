import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../../core/databases/api/dio_consumer.dart';

class WhatsAppApiService {
  DioConsumer get _api => Get.find<DioConsumer>();
  static const _base = '/whatsapp';
  static const _socialBase = '/social';

  Future<Map<String, dynamic>> getWhatsAppDashboard() =>
      _get('$_socialBase/dashboard');

  Future<Map<String, dynamic>> getWhatsAppConversations({
    String? search,
    String? status,
    String? channel,
    String? quickFilter,
    int page = 1,
  }) =>
      _get('$_socialBase/conversations', query: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'all') 'status': status,
        if (channel != null && channel != 'all') 'channel': channel,
        if (quickFilter != null && quickFilter != 'all')
          'quick_filter': quickFilter,
      });

  Future<Map<String, dynamic>> getWhatsAppConversationDetails(
    int id, {
    String channel = 'whatsapp',
    int page = 1,
  }) =>
      _get('$_socialBase/conversations/$channel/$id',
          query: {'page': page, 'per_page': 50});

  Future<Map<String, dynamic>> sendWhatsAppMessageToConversation(
    int id,
    String message, {
    String channel = 'whatsapp',
    int? replyToMessageId,
  }) =>
      _post('$_socialBase/conversations/$channel/$id/send', {
        'message': message,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      });

  Future<Map<String, dynamic>> resendMessage(
    int conversationId,
    int messageId, {
    String channel = 'whatsapp',
  }) =>
      _post(
          '$_socialBase/conversations/$channel/$conversationId/messages/$messageId/resend',
          const {});

  Future<Map<String, dynamic>> assignConversation(
    int conversationId, {
    required String channel,
    int? employeeId,
  }) =>
      _post('$_socialBase/conversations/$channel/$conversationId/assign',
          {'employee_id': employeeId});

  Future<Map<String, dynamic>> updateConversationTags(
    int conversationId, {
    required String channel,
    required List<String> tags,
  }) =>
      _post('$_socialBase/conversations/$channel/$conversationId/tags',
          {'tags': tags});

  Future<Map<String, dynamic>> requestConversationContinuation(int id) =>
      _post('$_base/conversations/$id/request-continuation', const {});

  Future<void> sendTypingIndicator(int id) async {
    await _api.post('$_base/conversations/$id/typing');
  }

  Future<Map<String, dynamic>> getProducts({String? search}) =>
      _get('$_base/products', query: {
        'per_page': 60,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      });

  Future<Map<String, dynamic>> sendProducts(
    int conversationId,
    List<String> productIds, {
    String channel = 'whatsapp',
  }) =>
      _post('$_socialBase/conversations/$channel/$conversationId/send-products',
          {'product_ids': productIds});

  Future<void> hideMessage(int conversationId, int messageId) async {
    await _api
        .delete('$_base/conversations/$conversationId/messages/$messageId');
  }

  Future<Map<String, dynamic>> sendWhatsAppMedia(
      int id, String path, String name,
      {String? caption, String? mediaKind, String channel = 'whatsapp'}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: name),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (mediaKind != null) 'media_kind': mediaKind,
    });
    final Response response = await _api
        .post('$_socialBase/conversations/$channel/$id/send-media', data: form);
    return _map(response.data);
  }

  Future<List<int>> getRemoteMedia(String url) async {
    final response =
        await _api.get(url, options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<Map<String, dynamic>> linkPerson(int id, String type, String name) =>
      _post('$_base/conversations/$id/link-person',
          {'person_type': type, 'name': name});

  Future<List<int>> getMedia(int messageId) async {
    final response = await _api.get('$_base/messages/$messageId/media',
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<List<int>> getQr({int? accountId}) async {
    final response = await _api.get('$_base/qr',
        queryParameters: _accountQuery(accountId),
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<List<int>> getQrPdf({int? accountId}) async {
    final response = await _api.get('$_base/qr/a4',
        queryParameters: _accountQuery(accountId),
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<Map<String, dynamic>> sendWhatsAppText(String phone, String message,
          {int? accountId}) =>
      _post('$_base/send-text', {
        'phone': phone,
        'message': message,
        ..._accountQuery(accountId),
      });

  Future<Map<String, dynamic>> getWhatsAppTemplates() =>
      _get('$_base/templates');

  Future<Map<String, dynamic>> createWhatsAppTemplate(
          Map<String, dynamic> data) =>
      _post('$_base/templates', data);

  Future<Map<String, dynamic>> updateWhatsAppTemplate(
      int id, Map<String, dynamic> data) async {
    final Response response =
        await _api.put('$_base/templates/$id', data: data);
    return _map(response.data);
  }

  Future<void> deleteWhatsAppTemplate(int id) async {
    await _api.delete('$_base/templates/$id');
  }

  Future<Map<String, dynamic>> getWhatsAppSettings() => _get('$_base/settings');

  Future<Map<String, dynamic>> saveWhatsAppSettings(
          Map<String, dynamic> data) =>
      _post('$_base/settings', data);

  Future<Map<String, dynamic>> updateWhatsAppEmployees(List<int> employeeIds) =>
      _post('$_base/settings/employees', {'employee_ids': employeeIds});

  Future<Map<String, dynamic>> sendWhatsAppTestMessage(
          String phone, String message,
          {int? accountId}) =>
      _post('$_base/test-message', {
        'phone': phone,
        'message': message,
        ..._accountQuery(accountId),
      });

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    final Response response = await _api.get(path, queryParameters: query);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> data) async {
    final Response response = await _api.post(path, data: data);
    return _map(response.data);
  }

  Map<String, dynamic> _map(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  Map<String, dynamic> _accountQuery(int? accountId) => {
        if (accountId != null && accountId > 0)
          'whatsapp_account_id': accountId,
      };
}
