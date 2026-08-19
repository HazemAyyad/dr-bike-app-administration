import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/bills_repository.dart';

class PurchaseWorkflowUsecase {
  final BillsRepository billsRepository;

  PurchaseWorkflowUsecase({required this.billsRepository});

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
  }) {
    return billsRepository.payPurchase(
      billId: billId,
      amount: amount,
      boxId: boxId,
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
}
