import 'package:doctorbike/core/helpers/json_safe_parser.dart';
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
    final j = Map<String, dynamic>.from(json);
    return FollowupModel(
      id: asInt(j['id']),
      customerName: asString(j['customer_name']),
      customerPhone: asString(j['customer_phone']),
      customerImg: ShowNetImage.getPhoto(asNullableString(j['customer_img'])),
      sellerName: asString(j['seller_name']),
      sellerPhone: asString(j['seller_phone']),
      sellerImg: ShowNetImage.getPhoto(asNullableString(j['seller_img'])),
      productName: asString(j['product_name']),
      followupStatus: asString(j['followup_status']),
      createdAt: parseApiDateTime(j['created_at']),
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
