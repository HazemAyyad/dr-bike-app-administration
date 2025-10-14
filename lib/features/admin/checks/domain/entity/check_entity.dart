class CheckEntity {
  final int id;
  final String? customerId;
  final String status;
  final String total;
  final DateTime dueDate;
  final String currency;
  final String checkId;
  final String bankName;
  final String? frontImage;
  final String? backImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sellerId;
  final Seller? customer;
  final Seller? seller;
  final Seller? fromCustomer;
  final Seller? fromSeller;
  final Seller? toCustomer;
  final Seller? toSeller;
  final String? notes;

  const CheckEntity({
    required this.id,
    this.customerId,
    required this.status,
    required this.total,
    required this.dueDate,
    required this.currency,
    required this.checkId,
    required this.bankName,
    this.frontImage,
    this.backImage,
    required this.createdAt,
    required this.updatedAt,
    this.sellerId,
    this.customer,
    this.seller,
    this.fromCustomer,
    this.fromSeller,
    this.toCustomer,
    this.toSeller,
    this.notes,
  });
}

class Seller {
  final int id;
  final String name;

  const Seller({
    required this.id,
    required this.name,
  });
}
