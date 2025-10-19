import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/bills_repository.dart';

class ChangeReturnToDeliveredUsecase {
  final BillsRepository billsRepository;

  ChangeReturnToDeliveredUsecase({required this.billsRepository});

  Future<Either<Failure, String>> call({required String returnPurchaseId}) {
    return billsRepository.changeReturnToDelivered(
      returnPurchaseId: returnPurchaseId,
    );
  }
}
