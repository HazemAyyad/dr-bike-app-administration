import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/debts_we_owe_model.dart';
import '../repositories/debts_repositories.dart';

class DebtsOwedToUsUsecase {
  final DebtsRepository debtsRepository;

  DebtsOwedToUsUsecase({required this.debtsRepository});

  Future<Either<Failure, DebtsWeOweModel>> call({required String token}) {
    return debtsRepository.debtsOwedToUs(token: token);
  }
}
