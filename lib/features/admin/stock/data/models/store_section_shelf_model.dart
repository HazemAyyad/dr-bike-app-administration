import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class StoreSectionShelfModel {
  final String id;
  final String sectionId;
  final String shelfNumber;
  final int sortOrder;
  final int productCount;

  StoreSectionShelfModel({
    required this.id,
    required this.sectionId,
    required this.shelfNumber,
    this.sortOrder = 0,
    this.productCount = 0,
  });

  factory StoreSectionShelfModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return StoreSectionShelfModel(
      id: asString(j['id']),
      sectionId: asString(j['store_section_id']),
      shelfNumber: asString(j['shelf_number']),
      sortOrder: asInt(j['sort_order'], 0),
      productCount: asInt(j['product_count'], 0),
    );
  }
}
