import '../../../../../../core/helpers/json_safe_parser.dart';

class AssetDepreciationPreview {
  final String period;
  final AssetDepreciationSummary summary;
  final List<AssetDepreciationPreviewRow> assets;
  final List<AssetDepreciationPreviewRow> skippedAssets;

  const AssetDepreciationPreview({
    required this.period,
    required this.summary,
    required this.assets,
    required this.skippedAssets,
  });

  factory AssetDepreciationPreview.fromJson(Map<String, dynamic> json) {
    List<AssetDepreciationPreviewRow> parseRows(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((row) => AssetDepreciationPreviewRow.fromJson(
                  Map<String, dynamic>.from(row),
                ))
            .toList()
        : <AssetDepreciationPreviewRow>[];

    return AssetDepreciationPreview(
      period: asString(json['period']),
      summary: AssetDepreciationSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      ),
      assets: parseRows(json['assets']),
      skippedAssets: parseRows(json['skipped_assets']),
    );
  }
}

class AssetDepreciationSummary {
  final int assetsCount;
  final int eligibleCount;
  final int skippedCount;
  final double valueBefore;
  final double depreciationAmount;
  final double valueAfter;

  const AssetDepreciationSummary({
    required this.assetsCount,
    required this.eligibleCount,
    required this.skippedCount,
    required this.valueBefore,
    required this.depreciationAmount,
    required this.valueAfter,
  });

  factory AssetDepreciationSummary.fromJson(Map<String, dynamic> json) =>
      AssetDepreciationSummary(
        assetsCount: asInt(json['assets_count']),
        eligibleCount: asInt(json['eligible_count']),
        skippedCount: asInt(json['skipped_count']),
        valueBefore: asDouble(json['value_before']),
        depreciationAmount: asDouble(json['depreciation_amount']),
        valueAfter: asDouble(json['value_after']),
      );
}

class AssetDepreciationPreviewRow {
  final int assetId;
  final String name;
  final String period;
  final double valueBefore;
  final double depreciationRate;
  final double depreciationAmount;
  final double valueAfter;
  final bool eligible;
  final bool alreadyDepreciated;
  final String skipReason;

  const AssetDepreciationPreviewRow({
    required this.assetId,
    required this.name,
    required this.period,
    required this.valueBefore,
    required this.depreciationRate,
    required this.depreciationAmount,
    required this.valueAfter,
    required this.eligible,
    required this.alreadyDepreciated,
    required this.skipReason,
  });

  factory AssetDepreciationPreviewRow.fromJson(Map<String, dynamic> json) =>
      AssetDepreciationPreviewRow(
        assetId: asInt(json['asset_id']),
        name: asString(json['name']),
        period: asString(json['period']),
        valueBefore: asDouble(json['value_before']),
        depreciationRate: asDouble(json['depreciation_rate']),
        depreciationAmount: asDouble(json['depreciation_amount']),
        valueAfter: asDouble(json['value_after']),
        eligible: asBool(json['eligible']),
        alreadyDepreciated: asBool(json['already_depreciated']),
        skipReason: asString(json['skip_reason']),
      );
}
