class FollowupModel {
  final int id;
  final String customerName;
  final String customerPhone;
  final String? sellerName;
  final String? sellerPhone;
  final String productName;
  final String followupStatus;

  FollowupModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.sellerName,
    this.sellerPhone,
    required this.productName,
    required this.followupStatus,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      sellerName: json['seller_name'],
      sellerPhone: json['seller_phone'],
      productName: json['product_name'] ?? '',
      followupStatus: json['followup_status'] ?? '',
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
