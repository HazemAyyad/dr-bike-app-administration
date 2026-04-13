import 'package:doctorbike/core/helpers/json_safe_parser.dart';

String _billSellerString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is num) return v.toString();
  if (v is Map) {
    final m = Map<String, dynamic>.from(v);
    if (m['name'] != null) return asString(m['name']);
    if (m['seller_name'] != null) return asString(m['seller_name']);
    final user = m['user'];
    if (user is Map) {
      final um = Map<String, dynamic>.from(user);
      if (um['name'] != null) return asString(um['name']);
    }
  }
  return asString(v);
}

String _billCreatedAtString(dynamic v) {
  if (v == null) return DateTime.now().toIso8601String();
  if (v is String) {
    if (v.isEmpty) return DateTime.now().toIso8601String();
    return v;
  }
  return parseApiDateTime(v).toIso8601String();
}

class BillDataModel {
  final int id;
  final String total;
  final String seller;
  final String createdAt;
  final String status;

  BillDataModel({
    required this.id,
    required this.total,
    required this.seller,
    required this.createdAt,
    required this.status,
  });

  factory BillDataModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);

    return BillDataModel(
      id: asInt(j['id']),
      total: asString(
        j['total'] ?? j['total_amount'] ?? j['amount'],
        '0.0',
      ),
      seller: _billSellerString(
        j['seller'] ?? j['seller_name'] ?? j['user'],
      ),
      createdAt: _billCreatedAtString(
        j['created_at'] ?? j['date'] ?? j['createdAt'],
      ),
      status: asString(j['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'seller': seller,
      'created_at': createdAt,
      'status': status,
    };
  }
}
