import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    return BillDataModel(
      id: asInt(json['id']),
      total: asString(json['total'], '0.0'),
      seller: asString(json['seller']),
      createdAt: asString(json['created_at']),
      status: asString(json['status']),
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
