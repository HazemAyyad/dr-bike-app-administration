import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../../core/databases/api/dio_consumer.dart';

class WhatsAppApiService {
  DioConsumer get _api => Get.find<DioConsumer>();
  static const _base = '/whatsapp';

  Future<Map<String, dynamic>> getWhatsAppDashboard() =>
      _get('$_base/dashboard');

  Future<Map<String, dynamic>> getWhatsAppConversations({
    String? search,
    String? status,
    int page = 1,
  }) =>
      _get('$_base/conversations', query: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'all') 'status': status,
      });

  Future<Map<String, dynamic>> getWhatsAppConversationDetails(int id,
          {int page = 1}) =>
      _get('$_base/conversations/$id', query: {'page': page, 'per_page': 50});

  Future<Map<String, dynamic>> sendWhatsAppMessageToConversation(
          int id, String message,
          {int? replyToMessageId}) =>
      _post('$_base/conversations/$id/send', {
        'message': message,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      });

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
          int conversationId, List<String> productIds) =>
      _post('$_base/conversations/$conversationId/send-products',
          {'product_ids': productIds});

  Future<void> hideMessage(int conversationId, int messageId) async {
    await _api
        .delete('$_base/conversations/$conversationId/messages/$messageId');
  }

  Future<Map<String, dynamic>> sendWhatsAppMedia(
      int id, String path, String name,
      {String? caption, String? mediaKind}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: name),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (mediaKind != null) 'media_kind': mediaKind,
    });
    final Response response =
        await _api.post('$_base/conversations/$id/send-media', data: form);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> linkPerson(int id, String type, String name) =>
      _post('$_base/conversations/$id/link-person',
          {'person_type': type, 'name': name});

  Future<List<int>> getMedia(int messageId) async {
    final response = await _api.get('$_base/messages/$messageId/media',
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<List<int>> getQr() async {
    final response = await _api.get('$_base/qr',
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<List<int>> getQrPdf() async {
    final response = await _api.get('$_base/qr/a4',
        options: Options(responseType: ResponseType.bytes));
    return List<int>.from(response.data as List);
  }

  Future<Map<String, dynamic>> sendWhatsAppText(String phone, String message) =>
      _post('$_base/send-text', {'phone': phone, 'message': message});

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
          String phone, String message) =>
      _post('$_base/test-message', {'phone': phone, 'message': message});

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
}
