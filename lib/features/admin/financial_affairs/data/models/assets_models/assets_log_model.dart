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
    return AssetLogModel(
      assetId: json['asset_id'] ?? '',
      assetName: json['asset_name'] ?? '',
      depreciationDate: DateTime.parse(json['date']),
      depreciationRate: json['depreciation_rate'] ?? '0',
      total: json['total'] ?? '0',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "asset_id": assetId,
      "asset_name": assetName,
      "date": depreciationDate.toIso8601String(),
      "depreciation_rate": depreciationRate,
      "total": total,
      "type": type,
    };
  }
}
