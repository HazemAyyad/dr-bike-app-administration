import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../../core/errors/failure.dart';
import '../repositories/counters_repository.dart';

class GetReportByTypeUsecase {
  final CountersRepository countersRepository;

  GetReportByTypeUsecase({required this.countersRepository});

  Future<Either<Failure, Uint8List>> call({
    required String type,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return countersRepository.getReportByType(
      type: type,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
