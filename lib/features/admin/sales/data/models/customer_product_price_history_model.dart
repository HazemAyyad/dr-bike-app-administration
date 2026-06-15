import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class CustomerProductPriceEntry {
  final double cost;
  final int invoiceId;
  final String soldAt;

  const CustomerProductPriceEntry({
    required this.cost,
    required this.invoiceId,
    required this.soldAt,
  });

  factory CustomerProductPriceEntry.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return CustomerProductPriceEntry(
      cost: asDouble(j['cost']),
      invoiceId: asInt(j['invoice_id']),
      soldAt: asString(j['sold_at']),
    );
  }
}

class CustomerProductPriceHistory {
  final double? lastPrice;
  final List<CustomerProductPriceEntry> entries;

  const CustomerProductPriceHistory({
    required this.lastPrice,
    required this.entries,
  });

  factory CustomerProductPriceHistory.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final rawLast = j['last_price'];
    final lastPrice = rawLast == null ? null : asDouble(rawLast);
    final entries = mapList(
      j['entries'],
      (m) => CustomerProductPriceEntry.fromJson(m),
    );
    return CustomerProductPriceHistory(
      lastPrice: lastPrice,
      entries: entries,
    );
  }

  bool get hasEntries => entries.isNotEmpty;
}
