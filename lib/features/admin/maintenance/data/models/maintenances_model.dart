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
  final String? contactPhone;
  final int? customerId;
  final int? sellerId;
  final double partsTotal;
  final double laborCost;
  final double invoiceTotal;
  final int? instantSaleId;

  MaintenanceDataModel({
    required this.id,
    required this.customerName,
    this.sellerName,
    this.contactPhone,
    this.customerId,
    this.sellerId,
    required this.receiptDate,
    required this.receiptTime,
    required this.createdAt,
    required this.status,
    required this.mediaFiles,
    this.partsTotal = 0,
    this.laborCost = 0,
    this.invoiceTotal = 0,
    this.instantSaleId,
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
      contactPhone: asNullableString(j['contact_phone']),
      customerId: j['customer_id'] == null ? null : asInt(j['customer_id']),
      sellerId: j['seller_id'] == null ? null : asInt(j['seller_id']),
      partsTotal: asDouble(j['parts_total']),
      laborCost: asDouble(j['labor_cost']),
      invoiceTotal: asDouble(j['invoice_total']),
      instantSaleId:
          j['instant_sale_id'] == null ? null : asInt(j['instant_sale_id']),
    );
  }
}
