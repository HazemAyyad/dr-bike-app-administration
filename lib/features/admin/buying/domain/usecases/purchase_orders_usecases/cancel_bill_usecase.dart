import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/bills_repository.dart';

class CancelBillUsecase {
  final BillsRepository billsRepository;

  CancelBillUsecase({required this.billsRepository});

  Future<Either<Failure, String>> call({required String billId}) {
    return billsRepository.cancelBill(billId: billId);
  }
}
