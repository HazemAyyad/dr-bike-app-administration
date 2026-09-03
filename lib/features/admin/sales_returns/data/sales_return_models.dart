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

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
