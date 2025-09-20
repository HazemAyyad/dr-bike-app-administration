import '../../../../../core/helpers/show_net_image.dart';

class MaintenanceDataModel {
  final int id;
  final String customerName;
  final String? sellerName;
  final String receiptDate;
  final String receiptTime;
  final String createdAt;
  final String status;
  final String mediaFiles;

  MaintenanceDataModel({
    required this.id,
    required this.customerName,
    this.sellerName,
    required this.receiptDate,
    required this.receiptTime,
    required this.createdAt,
    required this.status,
    required this.mediaFiles,
  });

  factory MaintenanceDataModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceDataModel(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      sellerName: json['seller_name'] ?? '',
      receiptDate: json['receipt_date'] ?? '',
      receiptTime: json['receipt_time'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
      mediaFiles: ShowNetImage.getPhoto(json['media_files']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'seller_name': sellerName,
      'receipt_date': receiptDate,
      'receipt_time': receiptTime,
      'created_at': createdAt,
      'status': status,
      'media_files': mediaFiles,
    };
  }
}
