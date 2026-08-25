import '../../../../../core/helpers/json_safe_parser.dart';
import 'maintenance_product_model.dart';

class MaintenanceInvoiceModel {
  final int maintenanceId;
  final String invoiceNumber;
  final String invoiceDate;
  final String invoiceDateDisplay;
  final String status;
  final String receiptDate;
  final String receiptTime;
  final String receiptDateTimeDisplay;
  final String description;
  final String notes;
  final List<MaintenanceInvoiceServiceModel> services;
  final String maintenanceStatusLabel;
  final String paymentStatus;
  final String paymentStatusLabel;
  final String customerTypeLabel;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<MaintenanceProductModel> items;
  final double partsTotal;
  final double laborCost;
  final double discount;
  final double invoiceTotal;
  final double paidAmount;
  final double remainingAmount;
  final double debtAmount;
  final bool hasDebt;
  final String currency;
  final List<MaintenanceInvoicePaymentModel> payments;
  final int? instantSaleId;
  final String? instantSaleSerial;
  final String qrPayload;

  const MaintenanceInvoiceModel({
    required this.maintenanceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceDateDisplay,
    required this.status,
    required this.receiptDate,
    required this.receiptTime,
    required this.receiptDateTimeDisplay,
    required this.description,
    this.notes = '',
    this.services = const [],
    required this.maintenanceStatusLabel,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    required this.customerTypeLabel,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.partsTotal,
    required this.laborCost,
    required this.discount,
    required this.invoiceTotal,
    required this.paidAmount,
    required this.remainingAmount,
    this.debtAmount = 0,
    this.hasDebt = false,
    this.currency = 'شيكل',
    this.payments = const [],
    this.instantSaleId,
    this.instantSaleSerial,
    required this.qrPayload,
  });

  factory MaintenanceInvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawPayments = json['payments'];
    final rawServices = json['services'];
    final maintenanceId = asInt(json['maintenance_id']);
    return MaintenanceInvoiceModel(
      maintenanceId: maintenanceId,
      invoiceNumber: asString(json['invoice_number']),
      invoiceDate: asString(json['invoice_date']),
      invoiceDateDisplay: asString(
        json['invoice_date_display'],
        asString(json['invoice_date']),
      ),
      status: asString(json['status']),
      receiptDate: asString(json['receipt_date']),
      receiptTime: asString(json['receipt_time']),
      receiptDateTimeDisplay: asString(
        json['receipt_datetime_display'],
        '${asString(json['receipt_date'])} ${asString(json['receipt_time'])}'
            .trim(),
      ),
      description: asString(json['description']),
      notes: asString(json['notes']),
      services: rawServices is List
          ? rawServices
              .map((e) => MaintenanceInvoiceServiceModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
      maintenanceStatusLabel: asString(json['maintenance_status_label']),
      paymentStatus: asString(json['payment_status']),
      paymentStatusLabel: asString(json['payment_status_label']),
      customerTypeLabel: asString(json['customer_type_label']),
      customerName: asString(json['customer_name'], '-'),
      customerPhone: asNullableString(json['customer_phone']),
      customerAddress: asNullableString(json['customer_address']),
      items: rawItems is List
          ? rawItems
              .map((e) => MaintenanceProductModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
      partsTotal: asDouble(json['parts_total']),
      laborCost: asDouble(json['labor_cost']),
      discount: asDouble(json['discount']),
      invoiceTotal: asDouble(json['invoice_total']),
      paidAmount: asDouble(json['paid_amount']),
      remainingAmount: asDouble(json['remaining_amount']),
      debtAmount: asDouble(
        json['debt_amount'],
        asDouble(json['remaining_amount']),
      ),
      hasDebt: json['has_debt'] is bool
          ? json['has_debt'] == true
          : asDouble(json['remaining_amount']) > 0,
      currency: asString(json['currency'], 'شيكل'),
      payments: rawPayments is List
          ? rawPayments
              .map((e) => MaintenanceInvoicePaymentModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
      instantSaleId: json['instant_sale_id'] == null
          ? null
          : asInt(json['instant_sale_id']),
      instantSaleSerial: asNullableString(json['instant_sale_serial']),
      qrPayload: asString(
        json['qr_payload'],
        'doctorbike://maintenance/invoice/$maintenanceId',
      ),
    );
  }
}

class MaintenanceInvoiceServiceModel {
  final int id;
  final String name;
  final double price;

  const MaintenanceInvoiceServiceModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory MaintenanceInvoiceServiceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceInvoiceServiceModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      price: asDouble(json['price']),
    );
  }
}

class MaintenanceInvoicePaymentModel {
  final int? id;
  final String method;
  final double amount;
  final String currency;
  final String? note;
  final String? createdAt;

  const MaintenanceInvoicePaymentModel({
    this.id,
    required this.method,
    required this.amount,
    this.currency = 'شيكل',
    this.note,
    this.createdAt,
  });

  factory MaintenanceInvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceInvoicePaymentModel(
      id: json['id'] == null ? null : asInt(json['id']),
      method: asString(json['method']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'شيكل'),
      note: asNullableString(json['note']),
      createdAt: asNullableString(json['created_at']),
    );
  }
}
