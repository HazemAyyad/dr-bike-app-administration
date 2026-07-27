import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class PersonProfileModel {
  final PersonProfilePerson person;
  final PersonProfileSummary summary;
  final List<PersonProfileInvoice> recentInvoices;
  final List<PersonProfileProduct> topProducts;
  final List<PersonProfileProduct> purchasedProducts;

  const PersonProfileModel({
    required this.person,
    required this.summary,
    required this.recentInvoices,
    required this.topProducts,
    required this.purchasedProducts,
  });

  factory PersonProfileModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileModel(
      person: PersonProfilePerson.fromJson(asMap(j['person'])),
      summary: PersonProfileSummary.fromJson(asMap(j['summary'])),
      recentInvoices: mapList(
        j['recent_invoices'],
        (m) => PersonProfileInvoice.fromJson(m),
      ),
      topProducts: mapList(
        j['top_products'],
        (m) => PersonProfileProduct.fromJson(m),
      ),
      purchasedProducts: mapList(
        j['purchased_products'],
        (m) => PersonProfileProduct.fromJson(m),
      ),
    );
  }
}

class PersonProfilePerson {
  final int id;
  final String type;
  final String name;
  final String phone;
  final String subPhone;
  final String jobTitle;
  final String address;
  final String category;

  const PersonProfilePerson({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.subPhone,
    required this.jobTitle,
    required this.address,
    required this.category,
  });

  factory PersonProfilePerson.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfilePerson(
      id: asInt(j['id']),
      type: asString(j['type']),
      name: asString(j['name']),
      phone: asString(j['phone']),
      subPhone: asString(j['sub_phone']),
      jobTitle: asString(j['job_title']),
      address: asString(j['address']),
      category: asString(j['category']),
    );
  }
}

class PersonProfileSummary {
  final int invoiceCount;
  final int distinctProductsCount;
  final double totalQuantity;
  final double totalPaid;
  final double debtOwedToUs;
  final double debtWeOwe;
  final double debtBalance;
  final String lastPurchaseAt;
  final double averageInvoiceTotal;

  const PersonProfileSummary({
    required this.invoiceCount,
    required this.distinctProductsCount,
    required this.totalQuantity,
    required this.totalPaid,
    required this.debtOwedToUs,
    required this.debtWeOwe,
    required this.debtBalance,
    required this.lastPurchaseAt,
    required this.averageInvoiceTotal,
  });

  factory PersonProfileSummary.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileSummary(
      invoiceCount: asInt(j['invoice_count']),
      distinctProductsCount: asInt(j['distinct_products_count']),
      totalQuantity: asDouble(j['total_quantity']),
      totalPaid: asDouble(j['total_paid']),
      debtOwedToUs: asDouble(j['debt_owed_to_us']),
      debtWeOwe: asDouble(j['debt_we_owe']),
      debtBalance: asDouble(j['debt_balance']),
      lastPurchaseAt: asString(j['last_purchase_at']),
      averageInvoiceTotal: asDouble(j['average_invoice_total']),
    );
  }
}

class PersonProfileInvoice {
  final String invoiceType;
  final int invoiceId;
  final String invoiceNumber;
  final String soldAt;
  final int itemsCount;
  final double quantity;
  final double total;

  const PersonProfileInvoice({
    required this.invoiceType,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.soldAt,
    required this.itemsCount,
    required this.quantity,
    required this.total,
  });

  factory PersonProfileInvoice.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileInvoice(
      invoiceType: asString(j['invoice_type']),
      invoiceId: asInt(j['invoice_id']),
      invoiceNumber: asString(j['invoice_number']),
      soldAt: asString(j['sold_at']),
      itemsCount: asInt(j['items_count']),
      quantity: asDouble(j['quantity']),
      total: asDouble(j['total']),
    );
  }
}

class PersonProfileProduct {
  final int productId;
  final String productName;
  final String productCode;
  final int purchaseCount;
  final double quantity;
  final double totalPaid;
  final double lastPrice;
  final double minPrice;
  final double maxPrice;
  final String lastPurchaseAt;

  const PersonProfileProduct({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.purchaseCount,
    required this.quantity,
    required this.totalPaid,
    required this.lastPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.lastPurchaseAt,
  });

  factory PersonProfileProduct.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileProduct(
      productId: asInt(j['product_id']),
      productName: asString(j['product_name']),
      productCode: asString(j['product_code']),
      purchaseCount: asInt(j['purchase_count']),
      quantity: asDouble(j['quantity']),
      totalPaid: asDouble(j['total_paid']),
      lastPrice: asDouble(j['last_price']),
      minPrice: asDouble(j['min_price']),
      maxPrice: asDouble(j['max_price']),
      lastPurchaseAt: asString(j['last_purchase_at']),
    );
  }
}

class PersonProductHistoryEntry {
  final double cost;
  final double quantity;
  final double lineTotal;
  final int invoiceId;
  final String invoiceNumber;
  final String invoiceType;
  final String soldAt;

  const PersonProductHistoryEntry({
    required this.cost,
    required this.quantity,
    required this.lineTotal,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.soldAt,
  });

  factory PersonProductHistoryEntry.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProductHistoryEntry(
      cost: asDouble(j['cost']),
      quantity: asDouble(j['quantity']),
      lineTotal: asDouble(j['line_total']),
      invoiceId: asInt(j['invoice_id']),
      invoiceNumber: asString(j['invoice_number']),
      invoiceType: asString(j['invoice_type']),
      soldAt: asString(j['sold_at']),
    );
  }
}
