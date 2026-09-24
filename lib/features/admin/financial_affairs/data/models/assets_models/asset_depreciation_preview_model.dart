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
  final double originalCost;
  final double currentBookValue;
  final int usefulLifeMonths;
  final int usedPeriods;
  final int remainingPeriods;
  final double depreciationRate;
  final double monthlyDepreciation;
  final double nextDepreciationAmount;
  final double depreciationAmount;
  final double valueAfter;
  final bool fullyDepreciated;
  final bool eligible;
  final bool alreadyDepreciated;
  final String skipReason;
  final String status;
  final String warning;

  const AssetDepreciationPreviewRow({
    required this.assetId,
    required this.name,
    required this.period,
    required this.valueBefore,
    required this.originalCost,
    required this.currentBookValue,
    required this.usefulLifeMonths,
    required this.usedPeriods,
    required this.remainingPeriods,
    required this.depreciationRate,
    required this.monthlyDepreciation,
    required this.nextDepreciationAmount,
    required this.depreciationAmount,
    required this.valueAfter,
    required this.fullyDepreciated,
    required this.eligible,
    required this.alreadyDepreciated,
    required this.skipReason,
    required this.status,
    required this.warning,
  });

  factory AssetDepreciationPreviewRow.fromJson(Map<String, dynamic> json) {
    final ratePercent = json.containsKey('depreciation_rate_percent')
        ? asDouble(json['depreciation_rate_percent'])
        : asDouble(json['depreciation_rate']) * 100;

    return AssetDepreciationPreviewRow(
      assetId: asInt(json['asset_id']),
      name: asString(json['name']),
      period: asString(json['period']),
      valueBefore: asDouble(json['value_before']),
      originalCost: asDouble(json['original_cost']),
      currentBookValue: asDouble(json['current_book_value']),
      usefulLifeMonths: asInt(json['useful_life_months']),
      usedPeriods: asInt(json['used_periods']),
      remainingPeriods: asInt(json['remaining_periods']),
      depreciationRate: ratePercent,
      monthlyDepreciation: asDouble(json['monthly_depreciation']),
      nextDepreciationAmount: asDouble(json['next_depreciation_amount']),
      depreciationAmount: asDouble(json['depreciation_amount']),
      valueAfter: asDouble(json['value_after']),
      fullyDepreciated: asBool(json['fully_depreciated']),
      eligible: asBool(json['eligible']),
      alreadyDepreciated: asBool(json['already_depreciated']),
      skipReason: asString(json['skip_reason']),
      status: asString(json['status']),
      warning: asString(json['warning']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'eligible':
        return 'جاهز للإهلاك';
      case 'already_depreciated':
        return 'تم إهلاكه لهذه الفترة';
      case 'fully_depreciated':
        return 'مُهلك بالكامل';
      case 'not_yet_acquired':
        return 'لم يبدأ الاستحقاق';
      case 'requires_review':
        return 'يحتاج مراجعة';
      default:
        return skipReason.isNotEmpty ? skipReason : 'غير معروف';
    }
  }
}
