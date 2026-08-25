import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class BillDetailsModel {
  final int billId;
  final List<BillProductModel> products;
  final String sellerId;
  final String sellerName;
  final String createdAt;
  final String totalBill;
  final String workflowStatus;
  final String paymentStatus;
  final String finalTotal;
  final String paidAmount;
  final String remainingAmount;
  final String customerId;
  final List<PurchasePaymentUiModel> payments;
  final List<PurchaseReturnUiModel> returns;
  final List<PurchaseAttachmentUiModel> attachments;
  final List<PurchaseTimelineUiModel> timeline;

  BillDetailsModel({
    required this.billId,
    required this.products,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.totalBill,
    required this.workflowStatus,
    required this.paymentStatus,
    required this.finalTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.customerId,
    required this.payments,
    required this.returns,
    required this.attachments,
    required this.timeline,
  });

  factory BillDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return BillDetailsModel(
      billId: asInt(j['bill_id']),
      products: mapList(
        j['products'],
        (Map<String, dynamic> m) => BillProductModel.fromJson(m),
      ),
      sellerId: asString(j['seller_id']),
      sellerName: asString(j['seller_name']),
      createdAt: asString(j['created_at']),
      totalBill: asString(j['total_bill'], '0.0'),
      workflowStatus: asString(j['workflow_status']),
      paymentStatus: asString(j['payment_status']),
      finalTotal: asString(j['final_total'], asString(j['total_bill'], '0')),
      paidAmount: asString(j['paid_amount'], '0'),
      remainingAmount: asString(j['remaining_amount'], '0'),
      customerId: asString(j['customer_id']),
      payments: mapList(
        j['payments'],
        (Map<String, dynamic> m) => PurchasePaymentUiModel.fromJson(m),
      ),
      returns: mapList(
        j['returns'],
        (Map<String, dynamic> m) => PurchaseReturnUiModel.fromJson(m),
      ),
      attachments: mapList(
        j['attachments'],
        (Map<String, dynamic> m) => PurchaseAttachmentUiModel.fromJson(m),
      ),
      timeline: mapList(
        j['timeline'],
        (Map<String, dynamic> m) => PurchaseTimelineUiModel.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'products': products.map((e) => e.toJson()).toList(),
      'seller_id': sellerId,
      'seller_name': sellerName,
      'created_at': createdAt,
      'total_bill': totalBill,
      'workflow_status': workflowStatus,
      'payment_status': paymentStatus,
      'final_total': finalTotal,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'customer_id': customerId,
      'payments': payments.map((e) => e.toJson()).toList(),
      'returns': returns.map((e) => e.toJson()).toList(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
    };
  }
}

class BillProductModel {
  final int billId;
  final String productId;
  final String productName;
  final String sizeId;
  final String sizeColorId;
  final String sizeLabel;
  final String colorLabel;
  final String productImage;
  final String quantity;
  final String price;
  final String productStatus;
  final num subTotal;
  final String extraAmount;
  final String missingAmount;
  final String notCompatibleAmount;
  final int billItemId;
  final num orderedQuantity;
  final num receivedOwnedQuantity;
  final num remainingQuantity;
  final num custodyQuantity;
  final num damagedQuantity;
  final num mismatchedQuantity;
  final List<PurchaseAmanatUiModel> amanatStocks;

  BillProductModel({
    required this.billId,
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeColorId,
    required this.sizeLabel,
    required this.colorLabel,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.productStatus,
    required this.subTotal,
    required this.extraAmount,
    required this.missingAmount,
    required this.notCompatibleAmount,
    required this.billItemId,
    required this.orderedQuantity,
    required this.receivedOwnedQuantity,
    required this.remainingQuantity,
    required this.custodyQuantity,
    required this.damagedQuantity,
    required this.mismatchedQuantity,
    required this.amanatStocks,
  });

  factory BillProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return BillProductModel(
      billId: asInt(j['bill_id']),
      productId: asString(j['product_id']),
      productName: asString(j['product_name']),
      sizeId: asString(j['size_id']),
      sizeColorId: asString(j['size_color_id']),
      sizeLabel: asString(j['size_label']),
      colorLabel: asString(j['color_label']),
      productImage: ShowNetImage.getPhoto(asNullableString(j['product_image'])),
      quantity: asString(j['quantity'], '0'),
      price: asString(j['price'], '0'),
      productStatus: asString(j['product_status']),
      subTotal: asDouble(j['sub_total']),
      extraAmount: asString(j['extra_amount']),
      missingAmount: asString(j['missing_amount']),
      notCompatibleAmount: asString(j['not_compatible_amount']),
      billItemId: asInt(j['bill_item_id'], asInt(j['id'])),
      orderedQuantity: asDouble(j['ordered_quantity'], asDouble(j['quantity'])),
      receivedOwnedQuantity: asDouble(j['received_owned_quantity']),
      remainingQuantity: asDouble(j['remaining_quantity']),
      custodyQuantity: asDouble(j['custody_quantity']),
      damagedQuantity: asDouble(j['damaged_quantity']),
      mismatchedQuantity: asDouble(j['mismatched_quantity']),
      amanatStocks: mapList(
        j['amanat_stocks'],
        (Map<String, dynamic> m) => PurchaseAmanatUiModel.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'product_id': productId,
      'product_name': productName,
      'size_id': sizeId,
      'size_color_id': sizeColorId,
      'size_label': sizeLabel,
      'color_label': colorLabel,
      'product_image': productImage,
      'quantity': quantity,
      'price': price,
      'product_status': productStatus,
      'sub_total': subTotal,
      'extra_amount': extraAmount,
      'missing_amount': missingAmount,
      'not_compatible_amount': notCompatibleAmount,
      'bill_item_id': billItemId,
      'ordered_quantity': orderedQuantity,
      'received_owned_quantity': receivedOwnedQuantity,
      'remaining_quantity': remainingQuantity,
      'custody_quantity': custodyQuantity,
      'damaged_quantity': damagedQuantity,
      'mismatched_quantity': mismatchedQuantity,
      'amanat_stocks': amanatStocks.map((e) => e.toJson()).toList(),
    };
  }

  String get variantLabel => [
        if (sizeLabel.trim().isNotEmpty) sizeLabel.trim(),
        if (colorLabel.trim().isNotEmpty) colorLabel.trim(),
      ].join(' / ');

  String get displayName =>
      variantLabel.isEmpty ? productName : '$productName — $variantLabel';
}

class PurchaseAmanatUiModel {
  final int id;
  final num quantity;
  final num remainingQuantity;
  final String status;
  final String negotiatedUnitPrice;
  final String notes;

  PurchaseAmanatUiModel({
    required this.id,
    required this.quantity,
    required this.remainingQuantity,
    required this.status,
    required this.negotiatedUnitPrice,
    required this.notes,
  });

  factory PurchaseAmanatUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchaseAmanatUiModel(
      id: asInt(j['id']),
      quantity: asDouble(j['quantity']),
      remainingQuantity: asDouble(j['remaining_quantity']),
      status: asString(j['status']),
      negotiatedUnitPrice: asString(j['negotiated_unit_price'], '0'),
      notes: asString(j['notes']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quantity': quantity,
        'remaining_quantity': remainingQuantity,
        'status': status,
        'negotiated_unit_price': negotiatedUnitPrice,
        'notes': notes,
      };
}

class PurchasePaymentUiModel {
  final int id;
  final String amount;
  final String paymentType;
  final String paidAt;
  final String boxId;
  final String boxName;
  final String note;

  PurchasePaymentUiModel({
    required this.id,
    required this.amount,
    required this.paymentType,
    required this.paidAt,
    required this.boxId,
    required this.boxName,
    required this.note,
  });

  factory PurchasePaymentUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchasePaymentUiModel(
      id: asInt(j['id']),
      amount: asString(j['amount'], '0'),
      paymentType: asString(j['payment_type']),
      paidAt: asString(j['paid_at']),
      boxId: asString(j['box_id']),
      boxName: asString(j['box_name']),
      note: asString(j['note']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'payment_type': paymentType,
        'paid_at': paidAt,
        'box_id': boxId,
        'box_name': boxName,
        'note': note,
      };
}

class PurchaseReturnUiModel {
  final int id;
  final String status;
  final String totalValue;
  final String createdAt;
  final List<PurchaseReturnItemUiModel> items;

  PurchaseReturnUiModel({
    required this.id,
    required this.status,
    required this.totalValue,
    required this.createdAt,
    required this.items,
  });

  factory PurchaseReturnUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchaseReturnUiModel(
      id: asInt(j['id']),
      status: asString(j['status']),
      totalValue: asString(j['total_value'], '0'),
      createdAt: asString(j['created_at']),
      items: mapList(
        j['items'],
        (Map<String, dynamic> m) => PurchaseReturnItemUiModel.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'total_value': totalValue,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class PurchaseReturnItemUiModel {
  final int id;
  final String productName;
  final String sizeLabel;
  final String colorLabel;
  final num quantity;
  final String unitPrice;

  PurchaseReturnItemUiModel({
    required this.id,
    required this.productName,
    required this.sizeLabel,
    required this.colorLabel,
    required this.quantity,
    required this.unitPrice,
  });

  factory PurchaseReturnItemUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchaseReturnItemUiModel(
      id: asInt(j['id']),
      productName: asString(j['product_name']),
      sizeLabel: asString(j['size_label']),
      colorLabel: asString(j['color_label']),
      quantity: asDouble(j['quantity']),
      unitPrice: asString(j['unit_price'], '0'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_name': productName,
        'size_label': sizeLabel,
        'color_label': colorLabel,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  String get variantLabel => [
        if (sizeLabel.trim().isNotEmpty) sizeLabel.trim(),
        if (colorLabel.trim().isNotEmpty) colorLabel.trim(),
      ].join(' / ');

  String get displayName =>
      variantLabel.isEmpty ? productName : '$productName — $variantLabel';
}

class PurchaseAttachmentUiModel {
  final int id;
  final String fileName;
  final String category;
  final String url;
  final String mimeType;
  final int size;
  final String createdAt;

  PurchaseAttachmentUiModel({
    required this.id,
    required this.fileName,
    required this.category,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.createdAt,
  });

  factory PurchaseAttachmentUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchaseAttachmentUiModel(
      id: asInt(j['id']),
      fileName: asString(j['file_name']),
      category: asString(j['category']),
      url: asString(j['url']),
      mimeType: asString(j['mime_type']),
      size: asInt(j['size']),
      createdAt: asString(j['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'category': category,
        'url': url,
        'mime_type': mimeType,
        'size': size,
        'created_at': createdAt,
      };
}

class PurchaseTimelineUiModel {
  final int id;
  final String action;
  final String title;
  final String description;
  final String createdAt;

  PurchaseTimelineUiModel({
    required this.id,
    required this.action,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory PurchaseTimelineUiModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchaseTimelineUiModel(
      id: asInt(j['id']),
      action: asString(j['action']),
      title: asString(j['title']),
      description: asString(j['description']),
      createdAt: asString(j['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'title': title,
        'description': description,
        'created_at': createdAt,
      };
}
