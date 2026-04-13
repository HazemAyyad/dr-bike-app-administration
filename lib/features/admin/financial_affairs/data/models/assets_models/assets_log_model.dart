import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class AssetLogModel {
  final String assetId;
  final String assetName;
  final DateTime depreciationDate;
  final String depreciationRate;
  final String total;
  final String type;

  AssetLogModel({
    required this.assetId,
    required this.assetName,
    required this.depreciationDate,
    required this.depreciationRate,
    required this.total,
    required this.type,
  });

  factory AssetLogModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return AssetLogModel(
      assetId: asString(j['asset_id']),
      assetName: asString(j['asset_name']),
      depreciationDate: parseApiDateTime(j['date']),
      depreciationRate: asString(j['depreciation_rate'], '0'),
      total: asString(j['total'], '0'),
      type: asString(j['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'asset_name': assetName,
      'date': depreciationDate.toIso8601String(),
      'depreciation_rate': depreciationRate,
      'total': total,
      'type': type,
    };
  }
}
