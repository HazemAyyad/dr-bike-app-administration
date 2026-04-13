import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/debts/domain/repositories/debts_repositories.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
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
        return Right(TotalDebtsOwedToUsModel.fromJson(asMap(result)));
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
        return Right(TotalDebtsWeOweModel.fromJson(asMap(result)));
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
        return Right(DebtsWeOweModel.fromJson(asMap(result)));
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
        return Right(DebtsWeOweModel.fromJson(asMap(result)));
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
      {required String customerId, required String sellerId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.userTransactionsData(
        customerId: customerId,
        sellerId: sellerId,
      );
      if (result['status'] == 'success') {
        return Right(UserTransactionsDataModel.fromJson(asMap(result)));
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
    required bool isCustomer,
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
    required String boxId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.addDebt(
        isCustomer: isCustomer,
        customerId: customerId,
        type: type,
        dueDate: dueDate,
        total: total,
        receiptImage: receiptImage,
        notes: notes,
        boxId: boxId,
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

  @override
  Future<Either<Failure, Uint8List>> getDebtsReports(
      {required String customerId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await debetDatasource.getDebtsReports(
        customerId: customerId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
