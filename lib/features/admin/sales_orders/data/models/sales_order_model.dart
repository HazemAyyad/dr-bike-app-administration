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

class SalesOrderShiplyTrackingEventModel {
  final int id;
  final int parcelStatusId;
  final String? statusKey;
  final String? statusLabel;
  final String? note;
  final String? source;
  final String? occurredAt;

  SalesOrderShiplyTrackingEventModel({
    required this.id,
    required this.parcelStatusId,
    this.statusKey,
    this.statusLabel,
    this.note,
    this.source,
    this.occurredAt,
  });

  factory SalesOrderShiplyTrackingEventModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderShiplyTrackingEventModel(
      id: json['id'] as int,
      parcelStatusId: json['parcel_status_id'] as int? ?? 0,
      statusKey: json['status_key'] as String?,
      statusLabel: json['status_label'] as String?,
      note: json['note'] as String?,
      source: json['source'] as String?,
      occurredAt: json['occurred_at'] as String?,
    );
  }
}

class SalesOrderShiplyTrackingModel {
  final String parcelCode;
  final String? shiplyMode;
  final int currentStatusId;
  final String? currentStatusKey;
  final String? currentStatusLabel;
  final List<int> statusSequence;
  final List<SalesOrderShiplyTrackingEventModel> events;

  SalesOrderShiplyTrackingModel({
    required this.parcelCode,
    this.shiplyMode,
    required this.currentStatusId,
    this.currentStatusKey,
    this.currentStatusLabel,
    this.statusSequence = const [],
    this.events = const [],
  });

  factory SalesOrderShiplyTrackingModel.fromJson(Map<String, dynamic> json) {
    final sequenceJson = json['status_sequence'] as List<dynamic>? ?? [];
    final eventsJson = json['events'] as List<dynamic>? ?? [];

    return SalesOrderShiplyTrackingModel(
      parcelCode: json['parcel_code'] as String? ?? '',
      shiplyMode: json['shiply_mode'] as String?,
      currentStatusId: json['current_status_id'] as int? ?? 0,
      currentStatusKey: json['current_status_key'] as String?,
      currentStatusLabel: json['current_status_label'] as String?,
      statusSequence: sequenceJson.map((e) => e as int).toList(),
      events: eventsJson
          .map((e) => SalesOrderShiplyTrackingEventModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
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

class SalesOrderHandoverModel {
  final int id;
  final String? deliveryCompanyName;
  final String? deliveryCompanyCode;
  final String? trackingNumber;
  final String? carrierContactName;
  final String? carrierContactPhone;
  final String? carrierOfficeName;
  final String? carrierVehicleNumber;
  final String? shiplyParcelCode;
  final String? handedOverAt;
  final String? deliveredAt;

  SalesOrderHandoverModel({
    required this.id,
    this.deliveryCompanyName,
    this.deliveryCompanyCode,
    this.trackingNumber,
    this.carrierContactName,
    this.carrierContactPhone,
    this.carrierOfficeName,
    this.carrierVehicleNumber,
    this.shiplyParcelCode,
    this.handedOverAt,
    this.deliveredAt,
  });

  factory SalesOrderHandoverModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderHandoverModel(
      id: json['id'] as int,
      deliveryCompanyName: json['delivery_company_name'] as String?,
      deliveryCompanyCode: json['delivery_company_code'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      carrierContactName: json['carrier_contact_name'] as String?,
      carrierContactPhone: json['carrier_contact_phone'] as String?,
      carrierOfficeName: json['carrier_office_name'] as String?,
      carrierVehicleNumber: json['carrier_vehicle_number'] as String?,
      shiplyParcelCode: json['shiply_parcel_code'] as String?,
      handedOverAt: json['handed_over_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
    );
  }

  bool get isTaxi => deliveryCompanyCode == 'taxi';

  bool get isOffice => deliveryCompanyCode == 'office';

  bool get isShiply => deliveryCompanyCode == 'shiply';
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
  final double? shiplyQuotedDeliveryFee;
  final double? shiplyDeliveryFeeAdjustment;
  final String paymentType;
  final double paymentAmount;
  final int? paymentBoxId;
  final String? notes;
  final int? instantSaleId;
  final String? instantSaleSerial;
  final String? trackingNumber;
  final int? deliveryCompanyId;
  final String? deliveryCompanyName;
  final String? deliveryCompanyCode;
  final SalesOrderHandoverModel? latestHandover;
  final int? shiplyCityId;
  final int? shiplyVillageId;
  final String? shiplyCityName;
  final String? shiplyVillageName;
  final String? shiplyAddressLabel;
  final String? customerAddress;
  final bool isShiplyDelivery;
  final List<SalesOrderItemModel> items;
  final List<SalesOrderMediaModel> media;
  final List<SalesOrderChildModel> childOrders;
  final List<SalesOrderStatusLogModel> statusLogs;
  final SalesOrderShiplyTrackingModel? shiplyTracking;
  final Map<String, SalesOrderMediaRequirementModel> mediaRequirements;

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
    this.shiplyQuotedDeliveryFee,
    this.shiplyDeliveryFeeAdjustment,
    required this.paymentType,
    this.paymentAmount = 0,
    this.paymentBoxId,
    this.notes,
    this.instantSaleId,
    this.instantSaleSerial,
    this.trackingNumber,
    this.deliveryCompanyId,
    this.deliveryCompanyName,
    this.deliveryCompanyCode,
    this.latestHandover,
    this.shiplyCityId,
    this.shiplyVillageId,
    this.shiplyCityName,
    this.shiplyVillageName,
    this.shiplyAddressLabel,
    this.customerAddress,
    this.isShiplyDelivery = false,
    required this.items,
    required this.media,
    this.childOrders = const [],
    this.statusLogs = const [],
    this.shiplyTracking,
    this.mediaRequirements = const {},
  });

  factory SalesOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final mediaJson = json['media'] as List<dynamic>? ?? [];
    final childJson = json['child_orders'] as List<dynamic>? ?? [];
    final logsJson = json['status_logs'] as List<dynamic>? ?? [];
    final trackingJson = json['shiply_tracking'] as Map<String, dynamic>?;
    final mediaReqRaw = json['media_requirements'];
    final mediaRequirements = <String, SalesOrderMediaRequirementModel>{};
    if (mediaReqRaw is Map) {
      for (final entry in mediaReqRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          mediaRequirements[entry.key.toString()] =
              SalesOrderMediaRequirementModel.fromJson(
            entry.key.toString(),
            value,
          );
        }
      }
    }

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
      shiplyQuotedDeliveryFee:
          (json['shiply_quoted_delivery_fee'] as num?)?.toDouble(),
      shiplyDeliveryFeeAdjustment:
          (json['shiply_delivery_fee_adjustment'] as num?)?.toDouble(),
      paymentType: json['payment_type'] as String? ?? 'cash',
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0,
      paymentBoxId: json['payment_box_id'] as int?,
      notes: json['notes'] as String?,
      instantSaleId: json['instant_sale_id'] as int?,
      instantSaleSerial: json['instant_sale_serial'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      deliveryCompanyId: json['delivery_company_id'] as int?,
      deliveryCompanyName: json['delivery_company_name'] as String?,
      deliveryCompanyCode: json['delivery_company_code'] as String?,
      latestHandover: json['latest_handover'] is Map<String, dynamic>
          ? SalesOrderHandoverModel.fromJson(
              json['latest_handover'] as Map<String, dynamic>,
            )
          : null,
      shiplyCityId: json['shiply_city_id'] as int?,
      shiplyVillageId: json['shiply_village_id'] as int?,
      shiplyCityName: json['shiply_city_name'] as String?,
      shiplyVillageName: json['shiply_village_name'] as String?,
      shiplyAddressLabel: json['shiply_address_label'] as String?,
      customerAddress: json['customer_address'] as String?,
      isShiplyDelivery: json['is_shiply_delivery'] == true,
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
      shiplyTracking: trackingJson != null
          ? SalesOrderShiplyTrackingModel.fromJson(trackingJson)
          : null,
      mediaRequirements: mediaRequirements,
    );
  }
}

class SalesOrderMediaModel {
  final int id;
  final String type;
  final String category;
  final String? url;

  SalesOrderMediaModel({
    required this.id,
    required this.type,
    this.category = 'general',
    this.url,
  });

  factory SalesOrderMediaModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderMediaModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'image',
      category: json['category'] as String? ?? 'general',
      url: json['url'] as String?,
    );
  }
}

class SalesOrderMediaRequirementModel {
  final String category;
  final String label;
  final bool satisfied;
  final bool optional;

  SalesOrderMediaRequirementModel({
    required this.category,
    required this.label,
    required this.satisfied,
    this.optional = false,
  });

  factory SalesOrderMediaRequirementModel.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return SalesOrderMediaRequirementModel(
      category: key,
      label: json['label'] as String? ?? key,
      satisfied: json['satisfied'] == true,
      optional: json['optional'] == true,
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

class ShiplyVillageModel {
  final int id;
  final String name;
  final bool isClosed;
  final String? note;

  ShiplyVillageModel({
    required this.id,
    required this.name,
    this.isClosed = false,
    this.note,
  });

  factory ShiplyVillageModel.fromJson(Map<String, dynamic> json) {
    return ShiplyVillageModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      isClosed: json['is_closed'] == true,
      note: json['note'] as String?,
    );
  }

  String displayLabel(String closedSuffix) {
    if (!isClosed) return name;
    final hint = (note ?? '').trim();
    return hint.isEmpty ? '$name ($closedSuffix)' : '$name ($closedSuffix — $hint)';
  }
}

class ShiplyCityModel {
  final int id;
  final String name;
  final List<ShiplyVillageModel> villages;

  ShiplyCityModel({
    required this.id,
    required this.name,
    required this.villages,
  });

  factory ShiplyCityModel.fromJson(Map<String, dynamic> json) {
    final villagesJson = json['villages'] as List<dynamic>? ?? [];
    return ShiplyCityModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      villages: villagesJson
          .map((e) => ShiplyVillageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShiplyAddressOptionsResult {
  final List<ShiplyCityModel> cities;
  final bool isTestMode;

  const ShiplyAddressOptionsResult({
    required this.cities,
    required this.isTestMode,
  });
}
