class SuspendedInvoiceGuard {
  static String? buyerIdentity(Map<String, dynamic> payload) {
    final type = payload['buyer_type']?.toString() ?? 'unknown';
    final id = type == 'seller' ? payload['seller_id'] : payload['buyer_id'];
    if (id != null && id.toString().isNotEmpty && id.toString() != '0') {
      return '$type:$id';
    }
    final name = payload['buyer_name']?.toString().trim() ?? '';
    return name.isEmpty ? null : '$type:$name';
  }

  static bool needsBuyerConfirmation(
    Map<String, dynamic> original,
    Map<String, dynamic> current,
  ) {
    final saved = buyerIdentity(original);
    return saved != null && saved != buyerIdentity(current);
  }
}
