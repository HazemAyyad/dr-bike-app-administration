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
  int returnedQuantity;
  int availableQuantity;
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
    required this.sourceInvoices,
    required this.sourceInvoiceNumbers,
    required this.accounting,
    required this.partnerId,
    required this.cancelledAt,
    required this.cancellationReason,
    required this.replacementSalesReturnId,
    required this.replacesSalesReturnId,
    required this.cancellationPreview,
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
  final List<SalesReturnSourceInvoice> sourceInvoices;
  final List<String> sourceInvoiceNumbers;
  final SalesReturnAccounting accounting;
  final int partnerId;
  final String cancelledAt;
  final String cancellationReason;
  final int replacementSalesReturnId;
  final int replacesSalesReturnId;
  final SalesReturnCancellationPreview cancellationPreview;

  bool get isSeller => partnerType == 'seller';
  bool get isCancelled => status == 'cancelled';

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
      sourceInvoices: (json['source_invoices'] as List? ?? const [])
          .whereType<Map>()
          .map((row) =>
              SalesReturnSourceInvoice.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      sourceInvoiceNumbers:
          (json['source_invoice_numbers'] as List? ?? const [])
              .map((value) => '$value')
              .where((value) => value.trim().isNotEmpty)
              .toList(),
      accounting: SalesReturnAccounting.fromJson(
        json['accounting'] is Map
            ? Map<String, dynamic>.from(json['accounting'] as Map)
            : const {},
      ),
      partnerId: _asInt(partner['id']),
      cancelledAt: '${json['cancelled_at'] ?? ''}',
      cancellationReason: '${json['cancellation_reason'] ?? ''}',
      replacementSalesReturnId: _asInt(json['replacement_sales_return_id']),
      replacesSalesReturnId: _asInt(json['replaces_sales_return_id']),
      cancellationPreview: SalesReturnCancellationPreview.fromJson(
        json['cancellation_preview'] is Map
            ? Map<String, dynamic>.from(json['cancellation_preview'] as Map)
            : const {},
      ),
    );
  }
}

class SalesReturnCancellationPreview {
  const SalesReturnCancellationPreview({
    required this.canCancel,
    required this.scenario,
    required this.title,
    required this.summary,
    required this.steps,
    required this.warnings,
  });

  final bool canCancel;
  final String scenario;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> warnings;

  factory SalesReturnCancellationPreview.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) => (value as List? ?? const [])
        .map((item) => '$item')
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return SalesReturnCancellationPreview(
      canCancel: json['can_cancel'] == true,
      scenario: '${json['scenario'] ?? ''}',
      title: '${json['title'] ?? 'مراجعة إلغاء المرتجع'}',
      summary: '${json['summary'] ?? ''}',
      steps: strings(json['steps']),
      warnings: strings(json['warnings']),
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
    required this.productId,
    required this.productCode,
    required this.productImage,
    required this.productImages,
    required this.sizeLabel,
    required this.colorLabel,
    required this.inventoryUnitCost,
    required this.inventoryTotalCost,
    required this.saleInvoice,
    required this.purchaseSources,
    required this.instantSaleId,
    required this.salesOrderItemId,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double originalUnitPrice;
  final double lineTotal;
  final String priceOverrideReason;
  final int productId;
  final String productCode;
  final String productImage;
  final List<String> productImages;
  final String sizeLabel;
  final String colorLabel;
  final double inventoryUnitCost;
  final double inventoryTotalCost;
  final SalesReturnSourceInvoice? saleInvoice;
  final List<SalesReturnPurchaseSource> purchaseSources;
  final int instantSaleId;
  final int salesOrderItemId;
  String get sourceType =>
      salesOrderItemId > 0 ? 'sales_order' : 'instant_sale';
  int get sourceItemId =>
      salesOrderItemId > 0 ? salesOrderItemId : instantSaleId;

  factory SalesReturnRecordItem.fromJson(Map<String, dynamic> json) =>
      SalesReturnRecordItem(
        productName: '${json['product_name'] ?? '-'}',
        quantity: _asInt(json['quantity']),
        unitPrice: _asDouble(json['unit_price']),
        originalUnitPrice: _asDouble(json['original_unit_price']),
        lineTotal: _asDouble(json['line_total']),
        priceOverrideReason: '${json['price_override_reason'] ?? ''}',
        productId: _asInt(json['product_id']),
        productCode: '${json['product_code'] ?? ''}',
        productImage: '${json['product_image'] ?? ''}',
        productImages: (json['product_images'] as List? ?? const [])
            .map((value) => '$value')
            .where((value) => value.trim().isNotEmpty)
            .toList(),
        sizeLabel: '${json['size_label'] ?? ''}',
        colorLabel: '${json['color_label'] ?? ''}',
        inventoryUnitCost: _asDouble(json['inventory_unit_cost']),
        inventoryTotalCost: _asDouble(json['inventory_total_cost']),
        saleInvoice: json['sale_invoice'] is Map
            ? SalesReturnSourceInvoice.fromJson(
                Map<String, dynamic>.from(json['sale_invoice'] as Map))
            : null,
        purchaseSources: (json['purchase_sources'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => SalesReturnPurchaseSource.fromJson(
                Map<String, dynamic>.from(row)))
            .toList(),
        instantSaleId: _asInt(json['instant_sale_id']),
        salesOrderItemId: _asInt(json['sales_order_item_id']),
      );
}

class SalesReturnSourceInvoice {
  const SalesReturnSourceInvoice({
    required this.type,
    required this.id,
    required this.serial,
    required this.date,
    required this.soldQuantity,
    required this.soldUnitPrice,
  });

  final String type;
  final int id;
  final String serial;
  final String date;
  final int soldQuantity;
  final double soldUnitPrice;
  bool get isSalesOrder => type == 'sales_order';
  String get typeLabel => isSalesOrder ? 'طلبية مبيعات' : 'فاتورة بيع فوري';

  factory SalesReturnSourceInvoice.fromJson(Map<String, dynamic> json) =>
      SalesReturnSourceInvoice(
        type: '${json['type'] ?? ''}',
        id: _asInt(json['id']),
        serial: '${json['serial'] ?? '-'}',
        date: '${json['date'] ?? ''}',
        soldQuantity: _asInt(json['sold_quantity']),
        soldUnitPrice: _asDouble(json['sold_unit_price']),
      );
}

class SalesReturnPurchaseSource {
  const SalesReturnPurchaseSource({
    required this.billId,
    required this.billDate,
    required this.invoiceQuantity,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.allocatedToSaleQuantity,
    required this.unitCost,
    required this.allocatedTotalCost,
    required this.currency,
  });

  final int billId;
  final String billDate;
  final double invoiceQuantity;
  final double orderedQuantity;
  final double receivedQuantity;
  final double allocatedToSaleQuantity;
  final double unitCost;
  final double allocatedTotalCost;
  final String currency;

  factory SalesReturnPurchaseSource.fromJson(Map<String, dynamic> json) =>
      SalesReturnPurchaseSource(
        billId: _asInt(json['bill_id']),
        billDate: '${json['bill_date'] ?? ''}',
        invoiceQuantity: _asDouble(json['invoice_quantity']),
        orderedQuantity: _asDouble(json['ordered_quantity']),
        receivedQuantity: _asDouble(json['received_quantity']),
        allocatedToSaleQuantity: _asDouble(json['allocated_to_sale_quantity']),
        unitCost: _asDouble(json['unit_cost']),
        allocatedTotalCost: _asDouble(json['allocated_total_cost']),
        currency: '${json['currency'] ?? 'شيكل'}',
      );
}

class SalesReturnAccounting {
  const SalesReturnAccounting({
    required this.grossReturn,
    required this.cashRefund,
    required this.creditRefund,
    required this.inventoryCostRestored,
    required this.marginReversed,
    required this.debtTransactionId,
    required this.refundBoxId,
  });

  final double grossReturn;
  final double cashRefund;
  final double creditRefund;
  final double inventoryCostRestored;
  final double marginReversed;
  final int debtTransactionId;
  final int refundBoxId;

  factory SalesReturnAccounting.fromJson(Map<String, dynamic> json) =>
      SalesReturnAccounting(
        grossReturn: _asDouble(json['gross_return']),
        cashRefund: _asDouble(json['cash_refund']),
        creditRefund: _asDouble(json['credit_refund']),
        inventoryCostRestored: _asDouble(json['inventory_cost_restored']),
        marginReversed: _asDouble(json['margin_reversed']),
        debtTransactionId: _asInt(json['debt_transaction_id']),
        refundBoxId: _asInt(json['refund_box_id']),
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
