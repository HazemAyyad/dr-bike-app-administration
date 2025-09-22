import 'package:dartz/dartz.dart';

import 'package:doctorbike/features/admin/buying/presentation/controllers/bills_controller.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/bills_repository.dart';
import '../datasources/bills_datasource.dart';

class BillsImplement implements BillsRepository {
  final NetworkInfo networkInfo;
  final BillsDatasource billsDataSource;

  BillsImplement({required this.networkInfo, required this.billsDataSource});

  // get bills
  @override
  Future<dynamic> getBills({required String page}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await billsDataSource.getBills(page: page);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // add bill
  @override
  Future<Either<Failure, String>> addBill({
    required String page,
    required String sellerId,
    required List<BillModel> products,
    required String total,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.addBill(
        page: page,
        sellerId: sellerId,
        products: products,
        total: total,
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
  Future<dynamic> getBillDetails({
    required String billId,
    required bool isDownload,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await billsDataSource.getBillDetails(
        billId: billId,
        isDownload: isDownload,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> cancelBill({required String billId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.cancelBill(billId: billId);
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

  // change product status
  @override
  Future<Either<Failure, String>> changeProductStatus({
    required String billId,
    required String productId,
    required String status,
    required String extraAmount,
    required String missingAmount,
    required String notCompatibleAmount,
    required String notCompatibleDescription,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeProductStatus(
        billId: billId,
        productId: productId,
        status: status,
        extraAmount: extraAmount,
        missingAmount: missingAmount,
        notCompatibleAmount: notCompatibleAmount,
        notCompatibleDescription: notCompatibleDescription,
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
  Future<Either<Failure, String>> changeOneProductStatus({
    required String billId,
    required String productId,
    required String price,
    required bool isDeliver,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeOneProductStatus(
        billId: billId,
        productId: productId,
        price: price,
        isDeliver: isDeliver,
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
  Future<Either<Failure, String>> changeReturnToDelivered(
      {required String returnPurchaseId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeReturnToDelivered(
        returnPurchaseId: returnPurchaseId,
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
