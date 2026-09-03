class SalesReturnPerson {
  const SalesReturnPerson(
      {required this.id,
      required this.type,
      required this.name,
      required this.phone});
  final int id;
  final String type;
  final String name;
  final String phone;
  bool get isCustomer => type == 'customer';
  String get typeLabel => isCustomer ? 'زبون' : 'تاجر/مورد';

  factory SalesReturnPerson.fromJson(Map<String, dynamic> json) =>
      SalesReturnPerson(
        id: _asInt(json['id']),
        type: '${json['type'] ?? 'customer'}',
        name: '${json['name'] ?? '-'}',
        phone: '${json['phone'] ?? ''}',
      );
}

class SalesReturnAvailableItem {
  SalesReturnAvailableItem({
    required this.sourceType,
    required this.sourceItemId,
    required this.invoiceId,
    required this.invoiceSerial,
    required this.invoiceDate,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.image,
    required this.sizeLabel,
    required this.colorLabel,
    required this.soldQuantity,
    required this.returnedQuantity,
    required this.availableQuantity,
    required this.originalUnitPrice,
  })  : quantity = 1,
        unitPrice = originalUnitPrice;

  final String sourceType;
  final int sourceItemId;
  final int invoiceId;
  final String invoiceSerial;
  final String invoiceDate;
  final int productId;
  final String productCode;
  final String productName;
  final String image;
  final String sizeLabel;
  final String colorLabel;
  final int soldQuantity;
  final int returnedQuantity;
  final int availableQuantity;
  final double originalUnitPrice;
  int quantity;
  double unitPrice;
  String priceOverrideReason = '';

  String get key => '$sourceType:$sourceItemId';
  double get lineTotal => quantity * unitPrice;
  bool get priceWasChanged => (unitPrice - originalUnitPrice).abs() > 0.001;

  factory SalesReturnAvailableItem.fromJson(Map<String, dynamic> json) =>
      SalesReturnAvailableItem(
        sourceType: '${json['source_type'] ?? ''}',
        sourceItemId: _asInt(json['source_item_id']),
        invoiceId: _asInt(json['invoice_id']),
        invoiceSerial: '${json['invoice_serial'] ?? '-'}',
        invoiceDate: '${json['invoice_date'] ?? ''}',
        productId: _asInt(json['product_id']),
        productCode: '${json['product_code'] ?? ''}',
        productName: '${json['product_name'] ?? '-'}',
        image: '${json['image'] ?? ''}',
        sizeLabel: '${json['size_label'] ?? ''}',
        colorLabel: '${json['color_label'] ?? ''}',
        soldQuantity: _asInt(json['sold_quantity']),
        returnedQuantity: _asInt(json['returned_quantity']),
        availableQuantity: _asInt(json['available_quantity']),
        originalUnitPrice: _asDouble(json['unit_price']),
      );

  Map<String, dynamic> toRequest() => {
        'source_type': sourceType,
        'source_item_id': sourceItemId,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (priceOverrideReason.trim().isNotEmpty)
          'price_override_reason': priceOverrideReason.trim(),
      };
}

class SalesReturnInvoiceGroup {
  const SalesReturnInvoiceGroup({
    required this.sourceType,
    required this.invoiceId,
    required this.invoiceSerial,
    required this.invoiceDate,
    required this.items,
  });

  final String sourceType;
  final int invoiceId;
  final String invoiceSerial;
  final String invoiceDate;
  final List<SalesReturnAvailableItem> items;

  String get key => '$sourceType:$invoiceId';
  String get sourceLabel =>
      sourceType == 'sales_order' ? 'طلبية مبيعات' : 'بيع فوري';
  int get availablePieces => items.fold<int>(
        0,
        (total, item) => total + item.availableQuantity,
      );
  double get availableValue => items.fold<double>(
        0,
        (total, item) =>
            total + item.availableQuantity * item.originalUnitPrice,
      );
}

class SalesReturnRecord {
  const SalesReturnRecord({
    required this.id,
    required this.serialNumber,
    required this.status,
    required this.totalAmount,
    required this.cashRefundAmount,
    required this.creditAmount,
    required this.currency,
    required this.partnerName,
    required this.partnerPhone,
    required this.partnerType,
    required this.itemsCount,
    required this.returnedQuantity,
    required this.completedAt,
    required this.note,
    required this.refundBoxName,
    required this.items,
  });

  final int id;
  final String serialNumber;
  final String status;
  final double totalAmount;
  final double cashRefundAmount;
  final double creditAmount;
  final String currency;
  final String partnerName;
  final String partnerPhone;
  final String partnerType;
  final int itemsCount;
  final int returnedQuantity;
  final String completedAt;
  final String note;
  final String refundBoxName;
  final List<SalesReturnRecordItem> items;

  bool get isSeller => partnerType == 'seller';

  factory SalesReturnRecord.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : null;
    final seller = json['seller'] is Map
        ? Map<String, dynamic>.from(json['seller'] as Map)
        : null;
    final partner = seller ?? customer ?? const <String, dynamic>{};
    final refundBox = json['refund_box'] is Map
        ? Map<String, dynamic>.from(json['refund_box'] as Map)
        : const <String, dynamic>{};
    final lines = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((line) =>
            SalesReturnRecordItem.fromJson(Map<String, dynamic>.from(line)))
        .toList();
    return SalesReturnRecord(
      id: _asInt(json['id']),
      serialNumber: '${json['serial_number'] ?? '-'}',
      status: '${json['status'] ?? 'completed'}',
      totalAmount: _asDouble(json['total_amount']),
      cashRefundAmount: _asDouble(json['cash_refund_amount']),
      creditAmount: _asDouble(json['credit_amount']),
      currency: '${json['currency'] ?? 'شيكل'}',
      partnerName: '${partner['name'] ?? '-'}',
      partnerPhone: '${partner['phone'] ?? ''}',
      partnerType: seller != null ? 'seller' : 'customer',
      itemsCount: _asInt(json['items_count'] ?? lines.length),
      returnedQuantity: _asInt(json['returned_quantity'] ??
          lines.fold<int>(0, (sum, line) => sum + line.quantity)),
      completedAt: '${json['completed_at'] ?? json['created_at'] ?? ''}',
      note: '${json['note'] ?? ''}',
      refundBoxName: '${refundBox['name'] ?? ''}',
      items: lines,
    );
  }
}

class SalesReturnRecordItem {
  const SalesReturnRecordItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.originalUnitPrice,
    required this.lineTotal,
    required this.priceOverrideReason,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double originalUnitPrice;
  final double lineTotal;
  final String priceOverrideReason;

  factory SalesReturnRecordItem.fromJson(Map<String, dynamic> json) =>
      SalesReturnRecordItem(
        productName: '${json['product_name'] ?? '-'}',
        quantity: _asInt(json['quantity']),
        unitPrice: _asDouble(json['unit_price']),
        originalUnitPrice: _asDouble(json['original_unit_price']),
        lineTotal: _asDouble(json['line_total']),
        priceOverrideReason: '${json['price_override_reason'] ?? ''}',
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
