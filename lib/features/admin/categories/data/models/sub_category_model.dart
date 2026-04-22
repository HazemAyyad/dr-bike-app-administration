import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class SubCategoryModel {
  final int id;
  final String nameAr;
  final String nameEng;
  final String nameAbree;
  final bool isShow;
  final int sortOrder;
  final int mainCategoryId;
  final String imageUrl;

  SubCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEng,
    required this.nameAbree,
    required this.isShow,
    this.sortOrder = 0,
    required this.mainCategoryId,
    this.imageUrl = '',
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: asInt(json['id']),
      nameAr: asString(json['nameAr']),
      nameEng: asString(json['nameEng']),
      nameAbree: asString(json['nameAbree']),
      isShow: asBool(json['isShow'], true),
      sortOrder: asInt(json['sortOrder']),
      mainCategoryId: asInt(json['mainCategoryId']),
      imageUrl: asString(json['imageUrl']),
    );
  }

  SubCategoryModel copyWith({
    int? id,
    String? nameAr,
    String? nameEng,
    String? nameAbree,
    bool? isShow,
    int? sortOrder,
    int? mainCategoryId,
    String? imageUrl,
  }) {
    return SubCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEng: nameEng ?? this.nameEng,
      nameAbree: nameAbree ?? this.nameAbree,
      isShow: isShow ?? this.isShow,
      sortOrder: sortOrder ?? this.sortOrder,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
