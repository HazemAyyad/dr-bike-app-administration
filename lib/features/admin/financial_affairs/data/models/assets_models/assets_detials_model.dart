import 'package:doctorbike/core/helpers/show_net_image.dart';

class AssetDetailsModel {
  final int id;
  final String name;
  final String price;
  final String? notes;
  final String depreciationRate;
  final String monthsNumber;
  final List<String> media;
  final List<AssetLog> logs;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssetDetailsModel({
    required this.id,
    required this.name,
    required this.price,
    this.notes,
    required this.depreciationRate,
    required this.monthsNumber,
    required this.media,
    required this.logs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetDetailsModel.fromJson(Map<String, dynamic> json) {
    final asset = json['asset'] ?? json; // في حال جاء الـ JSON مباشر من API
    return AssetDetailsModel(
      id: asset['id'],
      name: asset['name'] ?? '',
      price: asset['price'] ?? '',
      notes: asset['notes'] ?? '',
      depreciationRate: asset['depreciation_rate'] ?? '',
      monthsNumber: asset['months_number'] ?? '',
      media: List<String>.from(
        (asset['media'] ?? []).map((x) => ShowNetImage.getPhoto(x)),
      ),
      logs: asset['logs'] != null
          ? List<AssetLog>.from(
              asset['logs'].map((log) => AssetLog.fromJson(log)),
            )
          : [],
      createdAt: DateTime.parse(asset['created_at']),
      updatedAt: DateTime.parse(asset['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "price": price,
      "notes": notes,
      "depreciation_rate": depreciationRate,
      "months_number": monthsNumber,
      "media": media,
      "logs": logs.map((e) => e.toJson()).toList(),
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}

class AssetLog {
  final String total;
  final DateTime createdAt;
  final String type;

  AssetLog({
    required this.total,
    required this.createdAt,
    required this.type,
  });

  factory AssetLog.fromJson(Map<String, dynamic> json) {
    return AssetLog(
      total: json['total'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "total": total,
      "created_at": createdAt.toIso8601String(),
      "type": type,
    };
  }
}
