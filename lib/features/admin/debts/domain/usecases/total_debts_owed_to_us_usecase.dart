import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/total_debts_owed_to_us_model.dart';
import '../repositories/debts_repositories.dart';

class TotalDebtsOwedToUsUsecase {
  final DebtsRepository debtsRepository;

  TotalDebtsOwedToUsUsecase({required this.debtsRepository});

  Future<Either<Failure, TotalDebtsOwedToUsModel>> call() {
    return debtsRepository.totalDebtsOwedToUs();
  }
}
