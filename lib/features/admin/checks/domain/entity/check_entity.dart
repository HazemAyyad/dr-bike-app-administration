class CheckEntity {
  final int id;
  final int? parentOutgoingCheckId;
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
  final DateTime? receivedAt;
  final String? batchNumber;
  final String? sellerId;
  final Seller? customer;
  final Seller? seller;
  final Seller? fromCustomer;
  final Seller? fromSeller;
  final Seller? toCustomer;
  final Seller? toSeller;
  final String? notes;
  final double settledAmount;
  final double remainingAmount;
  final String settlementStatus;
  final List<CheckInstallment> installments;

  const CheckEntity({
    required this.id,
    this.parentOutgoingCheckId,
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
    this.receivedAt,
    this.batchNumber,
    this.sellerId,
    this.customer,
    this.seller,
    this.fromCustomer,
    this.fromSeller,
    this.toCustomer,
    this.toSeller,
    this.notes,
    this.settledAmount = 0,
    this.remainingAmount = 0,
    this.settlementStatus = 'unpaid',
    this.installments = const [],
  });
}

class CheckInstallment {
  final int id;
  final double amount;
  final DateTime dueDate;
  final String instrumentType;
  final String? checkId;
  final String? bankName;
  final String status;

  const CheckInstallment(
      {required this.id,
      required this.amount,
      required this.dueDate,
      required this.instrumentType,
      this.checkId,
      this.bankName,
      required this.status});
}

class Seller {
  final int id;
  final String name;
  final String phone;

  const Seller({
    required this.id,
    required this.name,
    this.phone = '',
  });
}
