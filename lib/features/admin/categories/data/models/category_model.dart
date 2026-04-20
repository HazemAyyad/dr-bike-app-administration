import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class CategoryModel {
  final int id;
  final String nameAr;
  final String nameEng;
  final String nameAbree;
  final bool isShow;
  final int subCategoriesCount;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEng,
    required this.nameAbree,
    required this.isShow,
    required this.subCategoriesCount,
    this.imageUrl = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: asInt(json['id']),
      nameAr: asString(json['nameAr']),
      nameEng: asString(json['nameEng']),
      nameAbree: asString(json['nameAbree']),
      isShow: asBool(json['isShow'], true),
      subCategoriesCount: asInt(json['sub_categories_count']),
      imageUrl: asString(json['imageUrl']),
    );
  }

  CategoryModel copyWith({
    int? id,
    String? nameAr,
    String? nameEng,
    String? nameAbree,
    bool? isShow,
    int? subCategoriesCount,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEng: nameEng ?? this.nameEng,
      nameAbree: nameAbree ?? this.nameAbree,
      isShow: isShow ?? this.isShow,
      subCategoriesCount: subCategoriesCount ?? this.subCategoriesCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
