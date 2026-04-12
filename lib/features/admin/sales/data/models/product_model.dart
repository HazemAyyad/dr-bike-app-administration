import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductModel {
  final String id;
  final String nameAr;
  final String stock;
  final List<dynamic> projects;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.stock,
    required this.projects,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final nameArCandidate = json['nameAr'] ?? json['name'];
    final projectsRaw = json['projects'];
    return ProductModel(
      id: asString(json['id']),
      nameAr: asString(nameArCandidate),
      stock: asString(json['stock']),
      projects: projectsRaw is List ? List<dynamic>.from(projectsRaw) : <dynamic>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'stock': stock,
      'projects': projects,
    };
  }
}
