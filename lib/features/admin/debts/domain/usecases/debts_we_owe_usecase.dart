import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/debts_we_owe_model.dart';
import '../repositories/debts_repositories.dart';

class DebtsWeOweUsecase {
  final DebtsRepository debtsRepository;

  DebtsWeOweUsecase({required this.debtsRepository});

  Future<Either<Failure, DebtsWeOweModel>> call() {
    return debtsRepository.debtsWeOwe();
  }
}
