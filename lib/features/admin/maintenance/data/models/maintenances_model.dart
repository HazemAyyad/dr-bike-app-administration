import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

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
    final j = Map<String, dynamic>.from(json);
    return MaintenanceDataModel(
      id: asInt(j['id']),
      customerName: asString(j['customer_name']),
      sellerName: asNullableString(j['seller_name']),
      receiptDate: asString(j['receipt_date']),
      receiptTime: asString(j['receipt_time']),
      createdAt: asString(j['created_at']),
      status: asString(j['status']),
      mediaFiles: ShowNetImage.getPhoto(asNullableString(j['media_files'])),
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
