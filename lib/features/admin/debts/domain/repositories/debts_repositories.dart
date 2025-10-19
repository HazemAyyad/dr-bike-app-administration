import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/debts_we_owe_model.dart';
import '../../data/models/total_debts_owed_to_us_model.dart';
import '../../data/models/total_debts_we_owe_model.dart';
import '../../data/models/user_transactions_data_model.dart';

abstract class DebtsRepository {
  Future<Either<Failure, TotalDebtsOwedToUsModel>> totalDebtsOwedToUs();

  Future<Either<Failure, TotalDebtsWeOweModel>> totalDebtsWeOwe();

  Future<Either<Failure, DebtsWeOweModel>> debtsWeOwe();

  Future<Either<Failure, DebtsWeOweModel>> debtsOwedToUs();

  Future<Either<Failure, UserTransactionsDataModel>> userTransactionsData(
      {required String customerId, required String sellerId});

  Future<Either<Failure, String>> addDebt({
    required bool isCustomer,
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
    required String boxId,
  });

  Future<Either<Failure, Uint8List>> getDebtsReports(
      {required String customerId});
}
