import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../../core/errors/failure.dart';
import '../repositories/counters_repository.dart';

class GetReportByTypeUsecase {
  final CountersRepository countersRepository;

  GetReportByTypeUsecase({required this.countersRepository});

  Future<Either<Failure, Uint8List>> call({
    required String type,
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? boxId,
    String? direction,
    List<String>? movementTypes,
    String? search,
    double? minAmount,
    double? maxAmount,
  }) {
    return countersRepository.getReportByType(
      type: type,
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
      boxId: boxId,
      direction: direction,
      movementTypes: movementTypes,
      search: search,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }
}
