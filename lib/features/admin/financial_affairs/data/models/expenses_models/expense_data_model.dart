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
    return ExpenseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.0',
      createdAt: DateTime.parse(json['created_at']),
      image: ShowNetImage.getPhoto(json['image']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "price": price,
      "created_at": createdAt.toIso8601String(),
      "image": image,
    };
  }
}
