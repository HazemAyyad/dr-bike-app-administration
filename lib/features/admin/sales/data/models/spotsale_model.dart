import 'package:doctorbike/core/databases/api/end_points.dart';

import '../../../../../core/helpers/show_net_image.dart';

class SpotsaleModel {
  final String status;
  final List<Spotsale> sales;

  SpotsaleModel({required this.status, required this.sales});

  factory SpotsaleModel.fromJson(Map<String, dynamic> json) {
    return SpotsaleModel(
      status: json[ApiKey.status],
      sales: (json[ApiKey.debts] as List<dynamic>)
          .map((e) => Spotsale.fromJson(e))
          .toList(),
    );
  }
}

class Spotsale {
  final int id;
  final String image;
  final List<Map<String, dynamic>> items;
  final String total;
  final String status;
  final DateTime debtCreatedAt;

  const Spotsale({
    required this.id,
    required this.image,
    required this.items,
    required this.total,
    required this.status,
    required this.debtCreatedAt,
  });

  factory Spotsale.fromJson(Map<String, dynamic> json) {
    return Spotsale(
      id: json[ApiKey.id] ?? 0,
      total: json[ApiKey.total] ?? '0',
      image: ShowNetImage.getPhoto(json[ApiKey.receipt_image]),
      status: json[ApiKey.status] ?? 'unpaid',
      items: (json[ApiKey.items] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      debtCreatedAt: DateTime.parse(
          json[ApiKey.debt_created_at] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.image: image,
      ApiKey.total: total,
      ApiKey.status: status,
      ApiKey.items: items,
      ApiKey.debt_created_at: debtCreatedAt.toIso8601String(),
    };
  }
}
