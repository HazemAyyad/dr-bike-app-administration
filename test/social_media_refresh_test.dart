import 'package:doctorbike/features/admin/whatsapp_center/data/whatsapp_api_service.dart';
import 'package:doctorbike/features/admin/whatsapp_center/data/whatsapp_models.dart';
import 'package:doctorbike/features/admin/whatsapp_center/presentation/controllers/whatsapp_center_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends WhatsAppApiService {
  int mediaRequests = 0;
  bool failMedia = false;

  @override
  Future<List<int>> getMedia(int id) async {
    mediaRequests++;
    if (failMedia) throw StateError('offline');
    return [1, 2, 3];
  }

  @override
  Future<Map<String, dynamic>> getWhatsAppConversations(
          {String? search,
          String? status,
          String? channel,
          String? quickFilter,
          int page = 1,
          int perPage = 20}) async =>
      {
        'conversations': {'data': [], 'current_page': 1, 'last_page': 1}
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refresh keeps downloaded previews; a new message gets new media',
      () async {
    final api = _Api();
    final controller = WhatsAppCenterController(api);
    final item = WhatsAppConversation.fromJson({
      'id': 1,
      'channel': 'whatsapp',
      'last_message_id': 10,
      'last_message_type': 'image',
    });
    await controller.conversationThumbnail(item);
    await controller.loadConversations();
    await controller.conversationThumbnail(item);
    await controller.loadConversations(silent: true);
    await controller.conversationThumbnail(item);
    expect(api.mediaRequests, 1);
    await controller.conversationThumbnail(WhatsAppConversation.fromJson({
      'id': 1,
      'channel': 'whatsapp',
      'last_message_id': 11,
      'last_message_type': 'image',
    }));
    expect(api.mediaRequests, 2);
    controller.onClose();
  });

  test('failed preview remains retryable after connectivity recovers',
      () async {
    final api = _Api()..failMedia = true;
    final controller = WhatsAppCenterController(api);
    final item = WhatsAppConversation.fromJson({
      'id': 1,
      'channel': 'whatsapp',
      'last_message_id': 10,
      'last_message_type': 'image',
    });
    expect(await controller.conversationThumbnail(item), isNull);
    api.failMedia = false;
    expect(await controller.conversationThumbnail(item), [1, 2, 3]);
    expect(api.mediaRequests, 2);
    controller.onClose();
  });
}
