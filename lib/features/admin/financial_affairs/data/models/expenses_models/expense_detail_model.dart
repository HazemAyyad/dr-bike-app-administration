import '../../../../../../core/helpers/show_net_image.dart';

class ExpenseDetailModel {
  final int id;
  final String name;
  final String price;
  final String paymentMethod;
  final String? notes;
  final List<String> invoiceImg;
  final List<String> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseDetailModel({
    required this.id,
    required this.name,
    required this.price,
    required this.paymentMethod,
    this.notes,
    required this.invoiceImg,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailModel(
      id: json['id'],
      name: json['name'],
      price: json['price'].toString(),
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      invoiceImg: List<String>.from(
          json['invoice_img'].map((x) => ShowNetImage.getPhoto(x))),
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
      "payment_method": paymentMethod,
      "notes": notes,
      "invoice_img": invoiceImg,
      "media": media,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}
