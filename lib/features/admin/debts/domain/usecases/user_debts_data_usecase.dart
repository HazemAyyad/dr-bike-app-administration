import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/user_transactions_data_model.dart';
import '../repositories/debts_repositories.dart';

class UserTransactionsUsecase {
  final DebtsRepository debtsRepository;

  UserTransactionsUsecase({required this.debtsRepository});

  Future<Either<Failure, UserTransactionsDataModel>> call(
      {required String customerId}) {
    return debtsRepository.userTransactionsData(customerId: customerId);
  }
}
