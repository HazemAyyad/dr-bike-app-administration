import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class StoreSectionModel {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final int productCount;
  final int shelfCount;

  StoreSectionModel({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
    this.shelfCount = 0,
  });

  factory StoreSectionModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final active = j['is_active'];
    final isActive = active == true ||
        active == 1 ||
        active == '1' ||
        active == 'true';
    return StoreSectionModel(
      id: asString(j['id']),
      name: asString(j['name']),
      description: asNullableString(j['description']),
      sortOrder: asInt(j['sort_order'], 0),
      isActive: isActive,
      productCount: asInt(j['product_count'], 0),
      shelfCount: asInt(j['shelf_count'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sort_order': sortOrder,
        'is_active': isActive,
        'product_count': productCount,
        'shelf_count': shelfCount,
      };
}
