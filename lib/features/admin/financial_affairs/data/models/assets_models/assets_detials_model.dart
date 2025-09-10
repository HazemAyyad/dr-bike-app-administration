import 'package:doctorbike/core/helpers/show_net_image.dart';

class AssetDetailsModel {
  final int id;
  final String name;
  final String price;
  final String? notes;
  final String depreciationRate;
  final String monthsNumber;
  final List<String> media;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetDetailsModel.fromJson(Map<String, dynamic> json) {
    return AssetDetailsModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      notes: json['notes'],
      depreciationRate: json['depreciation_rate'],
      monthsNumber: json['months_number'],
      media:
          List<String>.from(json['media'].map((x) => ShowNetImage.getPhoto(x))),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}
