import 'package:doctorbike/core/helpers/show_net_image.dart';

class FollowupModel {
  final int id;
  final String customerName;
  final String customerPhone;
  final String customerImg;
  final String sellerName;
  final String sellerPhone;
  final String sellerImg;
  final String productName;
  final String followupStatus;
  final DateTime createdAt;

  FollowupModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerImg,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerImg,
    required this.productName,
    required this.followupStatus,
    required this.createdAt,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerImg: ShowNetImage.getPhoto(json['customer_img']),
      sellerName: json['seller_name'] ?? '',
      sellerPhone: json['seller_phone'] ?? '',
      sellerImg: ShowNetImage.getPhoto(json['seller_img']),
      productName: json['product_name'] ?? '',
      followupStatus: json['followup_status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'product_name': productName,
      'followup_status': followupStatus,
    };
  }
}
