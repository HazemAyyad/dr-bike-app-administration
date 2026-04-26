import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductTagModel {
  final String id;
  final String name;
  final String color;
  final bool isActive;

  ProductTagModel({
    required this.id,
    required this.name,
    required this.color,
    this.isActive = true,
  });

  factory ProductTagModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final active = j['is_active'];
    final isActive = active == true ||
        active == 1 ||
        active == '1' ||
        active == 'true';
    return ProductTagModel(
      id: asString(j['id']),
      name: asString(j['name']),
      color: asString(j['color'], '#128C7E'),
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'is_active': isActive,
      };
}
