import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/debts_repositories.dart';

class TotalDebtsWeOweUsecase {
  final DebtsRepository debtsRepository;

  TotalDebtsWeOweUsecase({required this.debtsRepository});

  Future<Either<Failure, dynamic>> call({required String token}) {
    return debtsRepository.totalDebtsWeOwe(token: token);
  }
}
