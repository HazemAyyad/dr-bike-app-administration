import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class AddIncomingChecksBatchUsecase {
  final ChecksRepository checksRepository;

  AddIncomingChecksBatchUsecase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    String? customerId,
    String? sellerId,
    required DateTime receivedAt,
    required List<IncomingCheckBatchItem> checks,
  }) {
    return checksRepository.addIncomingChecksBatch(
      customerId: customerId,
      sellerId: sellerId,
      receivedAt: receivedAt,
      checks: checks,
    );
  }
}
