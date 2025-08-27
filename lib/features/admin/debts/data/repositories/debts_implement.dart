import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/debts/domain/repositories/debts_repositories.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../datasources/debet_datasource.dart';
import '../models/debts_we_owe_model.dart';
import '../models/total_debts_owed_to_us_model.dart';
import '../models/total_debts_we_owe_model.dart';
import '../models/user_transactions_data_model.dart';

class DebtsImplement implements DebtsRepository {
  final NetworkInfo networkInfo;
  final DebetDatasource debetDatasource;

  DebtsImplement({required this.networkInfo, required this.debetDatasource});

  @override
  Future<Either<Failure, TotalDebtsOwedToUsModel>> totalDebtsOwedToUs() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.totalDebtsOwedToUs();
      if (result['status'] == 'success') {
        return Right(TotalDebtsOwedToUsModel.fromJson(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, TotalDebtsWeOweModel>> totalDebtsWeOwe() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.totalDebtsWeOwe();
      if (result['status'] == 'success') {
        return Right(TotalDebtsWeOweModel.fromJson(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, DebtsWeOweModel>> debtsOwedToUs() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.debtsOwedToUs();
      if (result['status'] == 'success') {
        return Right(DebtsWeOweModel.fromJson(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, DebtsWeOweModel>> debtsWeOwe() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.debtsWeOwe();
      if (result['status'] == 'success') {
        return Right(DebtsWeOweModel.fromJson(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, UserTransactionsDataModel>> userTransactionsData(
      {required String customerId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await debetDatasource.userTransactionsData(customerId: customerId);
      if (result['status'] == 'success') {
        return Right(UserTransactionsDataModel.fromJson(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // addDebt
  @override
  Future<Either<Failure, String>> addDebt({
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.addDebt(
        customerId: customerId,
        type: type,
        dueDate: dueDate,
        total: total,
        receiptImage: receiptImage,
        notes: notes,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
