import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/bills_repository.dart';

class ChangeStatusUsecase {
  final BillsRepository billsRepository;

  ChangeStatusUsecase({required this.billsRepository});

  Future<Either<Failure, String>> call({
    required String billId,
    required String productId,
    required String status,
    required String extraAmount,
    required String missingAmount,
    required String notCompatibleAmount,
    required String notCompatibleDescription,
  }) {
    return billsRepository.changeProductStatus(
      billId: billId,
      productId: productId,
      status: status,
      extraAmount: extraAmount,
      missingAmount: missingAmount,
      notCompatibleAmount: notCompatibleAmount,
      notCompatibleDescription: notCompatibleDescription,
    );
  }
}
