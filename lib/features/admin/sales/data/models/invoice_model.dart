import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class InvoiceModel {
  final int id;
  final String product;
  final String productImage;
  final String cost;
  final String quantity;
  final String totalCost;
  final String discount;
  final List<SubProductModel> subProducts;

  final String invoiceNumber;
  final String invoiceDate;
  final String? traderName;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? paymentMethod;
  final String? saleStatus;
  final String? notes;
  final String subtotal;
  final String tax;
  final String paidAmount;
  final String remainingAmount;
  final String? projectName;

  InvoiceModel({
    required this.id,
    required this.product,
    required this.productImage,
    required this.cost,
    required this.quantity,
    required this.totalCost,
    required this.discount,
    required this.subProducts,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.traderName,
    this.customerName,
    this.phone,
    this.address,
    this.paymentMethod,
    this.saleStatus,
    this.notes,
    required this.subtotal,
    required this.tax,
    required this.paidAmount,
    required this.remainingAmount,
    this.projectName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: asInt(json['id']),
      product: asString(json['product']),
      productImage: asString(json['product_image']),
      cost: asString(json['cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      discount: asString(json['discount'], '0'),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductModel.fromJson(m),
      ),
      invoiceNumber: asString(json['invoice_number'], asString(json['id'])),
      invoiceDate: asString(json['invoice_date']),
      traderName: asNullableString(json['trader_name']),
      customerName: asNullableString(json['customer_name']),
      phone: asNullableString(json['phone']),
      address: asNullableString(json['address']),
      paymentMethod: asNullableString(json['payment_method']),
      saleStatus: asNullableString(json['sale_status']),
      notes: asNullableString(json['notes']),
      subtotal: asString(json['subtotal'], asString(json['total_cost'], '0')),
      tax: asString(json['tax'], '0'),
      paidAmount: asString(json['paid_amount'], asString(json['total_cost'], '0')),
      remainingAmount: asString(json['remaining_amount'], '0'),
      projectName: asNullableString(json['project_name']),
    );
  }

  String displayTraderName =>
      (traderName?.trim().isNotEmpty == true
              ? traderName
              : customerName?.trim().isNotEmpty == true
                  ? customerName
                  : projectName)
          ?.trim() ??
      '-';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_image': productImage,
      'cost': cost,
      'quantity': quantity,
      'total_cost': totalCost,
      'discount': discount,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'trader_name': traderName,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'payment_method': paymentMethod,
      'sale_status': saleStatus,
      'notes': notes,
      'subtotal': subtotal,
      'tax': tax,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'project_name': projectName,
    };
  }
}

class SubProductModel {
  final int id;
  final String productName;
  final String productImage;
  final String cost;
  final String quantity;
  final String subtotal;

  SubProductModel({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.cost,
    required this.quantity,
    required this.subtotal,
  });

  factory SubProductModel.fromJson(Map<String, dynamic> json) {
    final cost = asString(json['cost'], '0');
    final qty = asString(json['quantity'], '0');
    final parsedSubtotal = asString(json['subtotal'], '');
    final subtotal = parsedSubtotal.isNotEmpty
        ? parsedSubtotal
        : (double.tryParse(cost) ?? 0) * (double.tryParse(qty) ?? 0);

    return SubProductModel(
      id: asInt(json['id']),
      productName: asString(json['product_name']),
      productImage: asString(json['product_image']),
      cost: cost,
      quantity: qty,
      subtotal: subtotal.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_image': productImage,
      'cost': cost,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
