import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class AssetsModel {
  final List<Asset> assets;
  final String totalAssetsOriginalPrices;
  final String totalAssetsDepreciatePrices;
  final dynamic averageDepreciationRate;

  AssetsModel({
    required this.assets,
    required this.totalAssetsOriginalPrices,
    required this.totalAssetsDepreciatePrices,
    required this.averageDepreciationRate,
  });

  factory AssetsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return AssetsModel(
      assets: mapList(
        j['assets'],
        (Map<String, dynamic> m) => Asset.fromJson(m),
      ),
      totalAssetsOriginalPrices:
          asString(j['total_assets_original_prices']),
      totalAssetsDepreciatePrices:
          asString(j['total_assets_depreciate_prices']),
      averageDepreciationRate: j['average_depreciation_rate'] ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assets': assets.map((e) => e.toJson()).toList(),
      'total_assets_original_prices': totalAssetsOriginalPrices,
      'total_assets_depreciate_prices': totalAssetsDepreciatePrices,
      'average_depreciation_rate': averageDepreciationRate,
    };
  }
}

class Asset {
  final int assetId;
  final String name;
  final String originalPrice;
  final String depreciationRate;
  final String depreciationPrice;
  final DateTime createdAt;
  final String image;

  Asset({
    required this.assetId,
    required this.name,
    required this.originalPrice,
    required this.depreciationRate,
    required this.depreciationPrice,
    required this.createdAt,
    required this.image,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Asset(
      assetId: asInt(j['asset_id']),
      name: asString(j['name']),
      originalPrice: asString(j['original_price'], '0.0'),
      depreciationRate: asString(j['depreciation_rate'], '0.0'),
      depreciationPrice: asString(j['depreciation_price'], '0.0'),
      createdAt: parseApiDateTime(j['created_at']),
      image: ShowNetImage.getPhoto(asNullableString(j['image'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'name': name,
      'original_price': originalPrice,
      'depreciation_rate': depreciationRate,
      'depreciation_price': depreciationPrice,
      'created_at': createdAt.toIso8601String(),
      'image': image,
    };
  }
}
