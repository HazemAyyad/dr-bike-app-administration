import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/bills_repository.dart';

class PurchaseWorkflowUsecase {
  final BillsRepository billsRepository;

  PurchaseWorkflowUsecase({required this.billsRepository});

  Future<Either<Failure, String>> updateDraft({
    required String billId,
    required String sellerId,
    String customerId = '',
    required List<dynamic> products,
    required String total,
    String? notes,
  }) {
    return billsRepository.updatePurchaseDraft(
      billId: billId,
      sellerId: sellerId,
      customerId: customerId,
      products: products.cast(),
      total: total,
      notes: notes,
    );
  }

  Future<Either<Failure, String>> deleteDraft({required String billId}) {
    return billsRepository.deletePurchaseDraft(billId: billId);
  }

  Future<Either<Failure, String>> receive({
    required String billId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) {
    return billsRepository.receivePurchase(
      billId: billId,
      items: items,
      notes: notes,
    );
  }

  Future<Either<Failure, String>> finalize({
    required String billId,
    String initialPayment = '0',
    String? boxId,
  }) {
    return billsRepository.finalizePurchase(
      billId: billId,
      initialPayment: initialPayment,
      boxId: boxId,
    );
  }

  Future<Either<Failure, String>> pay({
    required String billId,
    required String amount,
    required String boxId,
    String? note,
    List<dynamic> evidenceFiles = const [],
  }) {
    return billsRepository.payPurchase(
      billId: billId,
      amount: amount,
      boxId: boxId,
      note: note,
      evidenceFiles: evidenceFiles,
    );
  }

  Future<Either<Failure, String>> paySupplierAccount({
    String sellerId = '',
    String customerId = '',
    required String amount,
    required String boxId,
    String? note,
    bool allocateOldestFirst = true,
    List<Map<String, dynamic>> allocations = const [],
    List<dynamic> evidenceFiles = const [],
  }) {
    return billsRepository.paySupplierAccount(
      sellerId: sellerId,
      customerId: customerId,
      amount: amount,
      boxId: boxId,
      note: note,
      allocateOldestFirst: allocateOldestFirst,
      allocations: allocations,
      evidenceFiles: evidenceFiles,
    );
  }

  Future<dynamic> openAccountBills({
    String sellerId = '',
    String customerId = '',
    String? currency,
  }) {
    return billsRepository.purchaseAccountOpenBills(
      sellerId: sellerId,
      customerId: customerId,
      currency: currency,
    );
  }

  Future<Either<Failure, String>> createPurchaseReturn({
    String sellerId = '',
    String customerId = '',
    String? billId,
    required List<dynamic> products,
    required String total,
    required String resolution,
    String? refundBoxId,
    String? note,
  }) {
    return billsRepository.createPurchaseReturn(
      sellerId: sellerId,
      customerId: customerId,
      billId: billId,
      products: products.cast(),
      total: total,
      resolution: resolution,
      refundBoxId: refundBoxId,
      note: note,
    );
  }

  Future<Either<Failure, String>> purchaseAmanat({
    required String amanatId,
    required String quantity,
    required String unitPrice,
  }) {
    return billsRepository.purchaseAmanat(
      amanatId: amanatId,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  Future<Either<Failure, String>> returnAmanat({
    required String amanatId,
    required String quantity,
    String? note,
  }) {
    return billsRepository.returnAmanat(
      amanatId: amanatId,
      quantity: quantity,
      note: note,
    );
  }

  Future<Either<Failure, String>> resolveIssue({
    required String billId,
    required String billItemId,
    required String issueType,
    required String resolution,
    required String quantity,
    String? negotiatedUnitPrice,
    String? financialAdjustment,
    String? reason,
    String? notes,
  }) {
    return billsRepository.resolvePurchaseIssue(
      billId: billId,
      billItemId: billItemId,
      issueType: issueType,
      resolution: resolution,
      quantity: quantity,
      negotiatedUnitPrice: negotiatedUnitPrice,
      financialAdjustment: financialAdjustment,
      reason: reason,
      notes: notes,
    );
  }

  Future<dynamic> timeline({required String billId}) {
    return billsRepository.purchaseTimeline(billId: billId);
  }

  Future<dynamic> priceIntelligence({
    required String productId,
    String? sellerId,
    String? customerId,
  }) {
    return billsRepository.purchasePriceIntelligence(
      productId: productId,
      sellerId: sellerId,
      customerId: customerId,
    );
  }

  Future<dynamic> amanatIndex({
    String? status,
    String? search,
  }) {
    return billsRepository.purchaseAmanatIndex(
      status: status,
      search: search,
    );
  }

  Future<dynamic> discrepancies({
    String? type,
    String? search,
  }) {
    return billsRepository.purchaseDiscrepancies(
      type: type,
      search: search,
    );
  }

  Future<Either<Failure, String>> uploadAttachments({
    required String billId,
    required List<dynamic> files,
    String category = 'evidence',
    String? attachableType,
    String? attachableId,
  }) {
    return billsRepository.uploadPurchaseAttachments(
      billId: billId,
      files: files,
      category: category,
      attachableType: attachableType,
      attachableId: attachableId,
    );
  }
}
