import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/bills_repository.dart';

class ChangeOneStatusUsecase {
  final BillsRepository billsRepository;

  ChangeOneStatusUsecase({required this.billsRepository});

  Future<Either<Failure, String>> call({
    required String billId,
    required String productId,
    required String price,
    required bool isDeliver,
  }) {
    return billsRepository.changeOneProductStatus(
      billId: billId,
      productId: productId,
      price: price,
      isDeliver: isDeliver,
    );
  }
}
