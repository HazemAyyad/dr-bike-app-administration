import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class PersonProfileModel {
  final PersonProfilePerson person;
  final PersonProfileSummary summary;
  final PersonProfileChecks checks;
  final List<PersonProfileInvoice> recentInvoices;
  final List<PersonProfileProduct> topProducts;
  final List<PersonProfileProduct> purchasedProducts;

  const PersonProfileModel({
    required this.person,
    required this.summary,
    required this.checks,
    required this.recentInvoices,
    required this.topProducts,
    required this.purchasedProducts,
  });

  factory PersonProfileModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileModel(
      person: PersonProfilePerson.fromJson(asMap(j['person'])),
      summary: PersonProfileSummary.fromJson(asMap(j['summary'])),
      checks: PersonProfileChecks.fromJson(asMap(j['checks'])),
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
  final String createdAt;
  final String? createdByName;

  const PersonProfilePerson({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.subPhone,
    required this.jobTitle,
    required this.address,
    required this.category,
    required this.createdAt,
    required this.createdByName,
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
      createdAt: asString(j['created_at']),
      createdByName: asNullableString(j['created_by_name']),
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
  final int checksFromPersonCount;
  final int checksFromPersonOpenCount;
  final int checksToPersonCount;
  final int checksToPersonOpenCount;

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
    required this.checksFromPersonCount,
    required this.checksFromPersonOpenCount,
    required this.checksToPersonCount,
    required this.checksToPersonOpenCount,
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
      checksFromPersonCount: asInt(j['checks_from_person_count']),
      checksFromPersonOpenCount: asInt(j['checks_from_person_open_count']),
      checksToPersonCount: asInt(j['checks_to_person_count']),
      checksToPersonOpenCount: asInt(j['checks_to_person_open_count']),
    );
  }
}

class PersonProfileChecks {
  final PersonProfileCheckSide fromPerson;
  final PersonProfileCheckSide toPerson;

  const PersonProfileChecks({
    required this.fromPerson,
    required this.toPerson,
  });

  factory PersonProfileChecks.fromJson(Map<String, dynamic> json) {
    return PersonProfileChecks(
      fromPerson: PersonProfileCheckSide.fromJson(asMap(json['from_person'])),
      toPerson: PersonProfileCheckSide.fromJson(asMap(json['to_person'])),
    );
  }
}

class PersonProfileCheckSide {
  final int count;
  final int openCount;
  final Map<String, double> totalsByCurrency;
  final Map<String, double> openTotalsByCurrency;

  const PersonProfileCheckSide({
    required this.count,
    required this.openCount,
    required this.totalsByCurrency,
    required this.openTotalsByCurrency,
  });

  factory PersonProfileCheckSide.fromJson(Map<String, dynamic> json) {
    return PersonProfileCheckSide(
      count: asInt(json['count']),
      openCount: asInt(json['open_count']),
      totalsByCurrency: _doubleMap(json['totals_by_currency']),
      openTotalsByCurrency: _doubleMap(json['open_totals_by_currency']),
    );
  }
}

Map<String, double> _doubleMap(dynamic value) {
  if (value is! Map) return const {};
  return value.map(
    (key, raw) => MapEntry(key.toString(), asDouble(raw)),
  );
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
  final String imageUrl;
  final int purchaseCount;
  final double quantity;
  final double totalPaid;
  final double lastPrice;
  final double minPrice;
  final double maxPrice;
  final double retailPrice;
  final double wholesalePrice;
  final double? customPrice;
  final String? priceRuleLabel;
  final double? priceRulePrice;
  final bool soldBelowWholesale;
  final bool soldBelowCustomPrice;
  final String lastPurchaseAt;

  const PersonProfileProduct({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.imageUrl,
    required this.purchaseCount,
    required this.quantity,
    required this.totalPaid,
    required this.lastPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.customPrice,
    required this.priceRuleLabel,
    required this.priceRulePrice,
    required this.soldBelowWholesale,
    required this.soldBelowCustomPrice,
    required this.lastPurchaseAt,
  });

  factory PersonProfileProduct.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PersonProfileProduct(
      productId: asInt(j['product_id']),
      productName: asString(j['product_name']),
      productCode: asString(j['product_code']),
      imageUrl: asString(j['image_url'], 'no image'),
      purchaseCount: asInt(j['purchase_count']),
      quantity: asDouble(j['quantity']),
      totalPaid: asDouble(j['total_paid']),
      lastPrice: asDouble(j['last_price']),
      minPrice: asDouble(j['min_price']),
      maxPrice: asDouble(j['max_price']),
      retailPrice: asDouble(j['retail_price']),
      wholesalePrice: asDouble(j['wholesale_price']),
      customPrice:
          j['custom_price'] == null ? null : asDouble(j['custom_price']),
      priceRuleLabel: asNullableString(j['price_rule_label']),
      priceRulePrice: j['price_rule_price'] == null
          ? null
          : asDouble(j['price_rule_price']),
      soldBelowWholesale: asBool(j['sold_below_wholesale']),
      soldBelowCustomPrice: asBool(j['sold_below_custom_price']),
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
  final String? priceRuleLabel;
  final double? priceRulePrice;
  final String soldAt;

  const PersonProductHistoryEntry({
    required this.cost,
    required this.quantity,
    required this.lineTotal,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.priceRuleLabel,
    required this.priceRulePrice,
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
      priceRuleLabel: asNullableString(j['price_rule_label']),
      priceRulePrice: j['price_rule_price'] == null
          ? null
          : asDouble(j['price_rule_price']),
      soldAt: asString(j['sold_at']),
    );
  }
}
