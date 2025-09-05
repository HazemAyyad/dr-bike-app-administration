import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/debts_repositories.dart';

class GetDebtsReportsUsecase {
  final DebtsRepository debtsRepository;

  GetDebtsReportsUsecase({required this.debtsRepository});

  Future<Either<Failure, Uint8List>> call({required String customerId}) {
    return debtsRepository.getDebtsReports(customerId: customerId);
  }
}
