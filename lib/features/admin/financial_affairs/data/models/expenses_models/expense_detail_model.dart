import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/helpers/show_net_image.dart';

class ExpenseDetailModel {
  final int id;
  final String name;
  final String price;
  final String boxId;
  final String boxName;
  final String expenseType;
  final DateTime expenseDate;
  final String? notes;
  final List<String> invoiceImg;
  final List<String> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseDetailModel({
    required this.id,
    required this.name,
    required this.price,
    required this.boxId,
    required this.boxName,
    required this.expenseType,
    required this.expenseDate,
    this.notes,
    required this.invoiceImg,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final box = asMap(j['box']);
    List<String> mapPhotoList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((x) => ShowNetImage.getPhoto(asNullableString(x)))
          .toList();
    }

    return ExpenseDetailModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      price: asString(j['price'], '0'),
      boxId: asString(box['id'], '0'),
      boxName: asString(box['name']),
      expenseType: asString(j['expense_type'], 'general'),
      expenseDate: parseApiDateTime(j['expense_date'] ?? j['created_at']),
      notes: asNullableString(j['notes']),
      invoiceImg: mapPhotoList(j['invoice_img']),
      media: mapPhotoList(j['media']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'box': boxId,
      'box_name': boxName,
      'expense_type': expenseType,
      'expense_date': expenseDate.toIso8601String(),
      'notes': notes,
      'invoice_img': invoiceImg,
      'media': media,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
