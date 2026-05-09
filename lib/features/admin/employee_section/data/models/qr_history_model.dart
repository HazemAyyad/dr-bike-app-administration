import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class QrHistoryItem {
  final int id;
  final String codeText;
  final String? qrImageUrl;
  final DateTime? createdAt;

  const QrHistoryItem({
    required this.id,
    required this.codeText,
    required this.qrImageUrl,
    required this.createdAt,
  });

  factory QrHistoryItem.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return QrHistoryItem(
      id: asInt(j['id']),
      codeText: asString(j['code_text']),
      qrImageUrl: j['qr_image_url'] == null
          ? null
          : ShowNetImage.getPhoto(asNullableString(j['qr_image_url'])),
      createdAt: j['created_at'] == null ? null : parseApiDateTime(j['created_at']),
    );
  }
}

class QrHistoryResult {
  final List<QrHistoryItem> items;
  final int currentPage;
  final int lastPage;

  const QrHistoryResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  factory QrHistoryResult.fromJson(Map<String, dynamic> json) {
    // يدعم استجابة مباشرة أو `data: { history, pagination }` مثل باقي الـ APIs
    final j = unwrapDataEnvelope(asMap(json));
    final status = asString(j['status']).toLowerCase();
    if (status == 'error') {
      throw FormatException(asString(j['message'], 'Request failed'));
    }
    final pagination = asMap(j['pagination']);
    final historyRaw = j['history'] ?? j['qr_history'];
    return QrHistoryResult(
      items: mapList(
        historyRaw,
        (m) => QrHistoryItem.fromJson(Map<String, dynamic>.from(m)),
      ),
      currentPage: asInt(pagination['current_page'], 1),
      lastPage: asInt(pagination['last_page'], 1),
    );
  }
}

