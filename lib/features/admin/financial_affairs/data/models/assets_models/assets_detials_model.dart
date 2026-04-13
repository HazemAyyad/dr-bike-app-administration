import 'package:doctorbike/core/helpers/json_safe_parser.dart';
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
    final root = Map<String, dynamic>.from(json);
    final assetRaw = root['asset'] ?? root;
    final asset = assetRaw is Map
        ? Map<String, dynamic>.from(assetRaw)
        : <String, dynamic>{};

    List<String> mapMedia(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((x) => ShowNetImage.getPhoto(asNullableString(x))).toList();
    }

    return AssetDetailsModel(
      id: asInt(asset['id']),
      name: asString(asset['name']),
      price: asString(asset['price']),
      notes: asNullableString(asset['notes']),
      depreciationRate: asString(asset['depreciation_rate']),
      monthsNumber: asString(asset['months_number']),
      media: mapMedia(asset['media']),
      logs: mapList(
        asset['logs'],
        (Map<String, dynamic> m) => AssetLog.fromJson(m),
      ),
      createdAt: parseApiDateTime(asset['created_at']),
      updatedAt: parseApiDateTime(asset['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'notes': notes,
      'depreciation_rate': depreciationRate,
      'months_number': monthsNumber,
      'media': media,
      'logs': logs.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
    final j = Map<String, dynamic>.from(json);
    return AssetLog(
      total: asString(j['total']),
      createdAt: parseApiDateTime(j['created_at']),
      type: asString(j['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }
}
