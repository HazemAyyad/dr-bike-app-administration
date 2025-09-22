class BillDataModel {
  final int id;
  final String total;
  final String seller;
  final String createdAt;
  final String status;

  BillDataModel({
    required this.id,
    required this.total,
    required this.seller,
    required this.createdAt,
    required this.status,
  });

  factory BillDataModel.fromJson(Map<String, dynamic> json) {
    return BillDataModel(
      id: json['id'] ?? 0,
      total: json['total'] ?? "0.0",
      seller: json['seller'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'seller': seller,
      'created_at': createdAt,
      'status': status,
    };
  }
}
