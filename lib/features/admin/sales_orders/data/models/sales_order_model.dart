class SalesOrderListItemModel {
  final int id;
  final String? serialNumber;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final String? cityName;
  final double total;
  final String paymentType;
  final String? createdAt;
  final String? createdByName;

  SalesOrderListItemModel({
    required this.id,
    this.serialNumber,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.cityName,
    required this.total,
    required this.paymentType,
    this.createdAt,
    this.createdByName,
  });

  factory SalesOrderListItemModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderListItemModel(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String? ?? 'unconfirmed',
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      cityName: json['city_name'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentType: json['payment_type'] as String? ?? 'cash',
      createdAt: json['created_at'] as String?,
      createdByName: json['created_by_name'] as String?,
    );
  }
}

class SalesOrderItemModel {
  final int id;
  final int productId;
  final String? productName;
  final String? productImage;
  final int? sizeId;
  final int? sizeColorId;
  final String? sizeLabel;
  final String? colorLabel;
  final int quantity;
  final int deliveredQty;
  final int dispatchedQty;
  final int returnedQty;
  final double unitPrice;
  final double lineTotal;

  SalesOrderItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productImage,
    this.sizeId,
    this.sizeColorId,
    this.sizeLabel,
    this.colorLabel,
    required this.quantity,
    this.deliveredQty = 0,
    this.dispatchedQty = 0,
    this.returnedQty = 0,
    required this.unitPrice,
    required this.lineTotal,
  });

  int get pendingDeliverQty => quantity - deliveredQty;

  int get returnableQty => dispatchedQty - deliveredQty - returnedQty;

  factory SalesOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      productImage: json['product_image'] as String?,
      sizeId: json['size_id'] as int?,
      sizeColorId: json['size_color_id'] as int?,
      sizeLabel: json['size_label'] as String?,
      colorLabel: json['color_label'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      deliveredQty: json['delivered_qty'] as int? ?? 0,
      dispatchedQty: json['dispatched_qty'] as int? ?? 0,
      returnedQty: json['returned_qty'] as int? ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesOrderStatusLogModel {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final String? userName;
  final String? createdAt;

  SalesOrderStatusLogModel({
    this.fromStatus,
    required this.toStatus,
    this.note,
    this.userName,
    this.createdAt,
  });

  factory SalesOrderStatusLogModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderStatusLogModel(
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? '',
      note: json['note'] as String?,
      userName: json['user_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class SalesOrderChildModel {
  final int id;
  final String? serialNumber;
  final String status;
  final double total;

  SalesOrderChildModel({
    required this.id,
    this.serialNumber,
    required this.status,
    required this.total,
  });

  factory SalesOrderChildModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderChildModel(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String? ?? 'unconfirmed',
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesOrderDetailModel {
  final int id;
  final String? serialNumber;
  final String status;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? cityName;
  final int? cityId;
  final double total;
  final double subtotal;
  final double discount;
  final double customerDeliveryFee;
  final String paymentType;
  final double paymentAmount;
  final int? paymentBoxId;
  final String? notes;
  final int? instantSaleId;
  final String? instantSaleSerial;
  final String? trackingNumber;
  final String? deliveryCompanyName;
  final List<SalesOrderItemModel> items;
  final List<SalesOrderMediaModel> media;
  final List<SalesOrderChildModel> childOrders;
  final List<SalesOrderStatusLogModel> statusLogs;

  SalesOrderDetailModel({
    required this.id,
    this.serialNumber,
    required this.status,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.cityName,
    this.cityId,
    required this.total,
    required this.subtotal,
    required this.discount,
    required this.customerDeliveryFee,
    required this.paymentType,
    this.paymentAmount = 0,
    this.paymentBoxId,
    this.notes,
    this.instantSaleId,
    this.instantSaleSerial,
    this.trackingNumber,
    this.deliveryCompanyName,
    required this.items,
    required this.media,
    this.childOrders = const [],
    this.statusLogs = const [],
  });

  factory SalesOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final mediaJson = json['media'] as List<dynamic>? ?? [];
    final childJson = json['child_orders'] as List<dynamic>? ?? [];
    final logsJson = json['status_logs'] as List<dynamic>? ?? [];
    return SalesOrderDetailModel(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String? ?? 'unconfirmed',
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      cityName: (json['city'] as Map<String, dynamic>?)?['name_ar'] as String?,
      cityId: json['city_id'] as int?,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      customerDeliveryFee:
          (json['customer_delivery_fee'] as num?)?.toDouble() ?? 0,
      paymentType: json['payment_type'] as String? ?? 'cash',
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0,
      paymentBoxId: json['payment_box_id'] as int?,
      notes: json['notes'] as String?,
      instantSaleId: json['instant_sale_id'] as int?,
      instantSaleSerial: json['instant_sale_serial'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      deliveryCompanyName: json['delivery_company_name'] as String?,
      items: itemsJson
          .map((e) => SalesOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      media: mediaJson
          .map((e) => SalesOrderMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      childOrders: childJson
          .map((e) => SalesOrderChildModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusLogs: logsJson
          .map((e) =>
              SalesOrderStatusLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SalesOrderMediaModel {
  final int id;
  final String type;
  final String? url;

  SalesOrderMediaModel({required this.id, required this.type, this.url});

  factory SalesOrderMediaModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderMediaModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String?,
    );
  }
}

class DeliveryCompanyModel {
  final int id;
  final String name;
  final String? code;

  DeliveryCompanyModel({required this.id, required this.name, this.code});

  factory DeliveryCompanyModel.fromJson(Map<String, dynamic> json) {
    return DeliveryCompanyModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }
}

class CityModel {
  final int id;
  final String nameAr;
  final double? deliveryFee;

  CityModel({
    required this.id,
    required this.nameAr,
    this.deliveryFee,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String? ?? '',
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
    );
  }
}
