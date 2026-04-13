import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class ExpenseModel {
  final int id;
  final String name;
  final String price;
  final DateTime createdAt;
  final String? image;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
    this.image,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ExpenseModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      price: asString(j['price'], '0.0'),
      createdAt: parseApiDateTime(j['created_at']),
      image: ShowNetImage.getPhoto(asNullableString(j['image'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'image': image,
    };
  }
}
