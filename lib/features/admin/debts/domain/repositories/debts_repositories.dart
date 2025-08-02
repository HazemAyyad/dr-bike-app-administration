import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/debts_we_owe_model.dart';
import '../../data/models/total_debts_owed_to_us_model.dart';
import '../../data/models/total_debts_we_owe_model.dart';
import '../../data/models/user_transactions_data_model.dart';

abstract class DebtsRepository {
  Future<Either<Failure, TotalDebtsOwedToUsModel>> totalDebtsOwedToUs(
      {required String token});

  Future<Either<Failure, TotalDebtsWeOweModel>> totalDebtsWeOwe(
      {required String token});

  Future<Either<Failure, DebtsWeOweModel>> debtsWeOwe({required String token});

  Future<Either<Failure, DebtsWeOweModel>> debtsOwedToUs(
      {required String token});

  Future<Either<Failure, UserTransactionsDataModel>> userTransactionsData(
      {required String token, required String customerId});
}
