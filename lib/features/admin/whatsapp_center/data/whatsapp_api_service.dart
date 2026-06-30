import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

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
          int id, String message) =>
      _post('$_base/conversations/$id/send', {'message': message});

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
