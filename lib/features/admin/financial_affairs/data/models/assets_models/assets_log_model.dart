import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class AssetLogModel {
  final String assetId;
  final String assetName;
  final DateTime depreciationDate;
  final String depreciationRate;
  final String total;
  final String type;
  final String depreciationPeriod;
  final double valueBefore;
  final double depreciationAmount;

  AssetLogModel({
    required this.assetId,
    required this.assetName,
    required this.depreciationDate,
    required this.depreciationRate,
    required this.total,
    required this.type,
    required this.depreciationPeriod,
    required this.valueBefore,
    required this.depreciationAmount,
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
      depreciationPeriod: asString(j['depreciation_period']),
      valueBefore: asDouble(j['value_before']),
      depreciationAmount: asDouble(j['depreciation_amount']),
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
      'depreciation_period': depreciationPeriod,
      'value_before': valueBefore,
      'depreciation_amount': depreciationAmount,
    };
  }
}
