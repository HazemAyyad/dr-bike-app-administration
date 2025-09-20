import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/followup_repository.dart';
import '../datasources/followup_datasource.dart';
import '../models/followup_modle.dart';

class FollowupImplement implements FollowupRepository {
  final NetworkInfo networkInfo;
  final FollowupDatasource followupDataSource;

  FollowupImplement(
      {required this.networkInfo, required this.followupDataSource});

  @override
  Future<List<FollowupModel>> getFollowup({required int page}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await followupDataSource.getFollowup(page: page);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> addAndUpdateFollowup({
    required String followupId,
    required String customerId,
    required String sellerId,
    required String productId,
    required String status,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await followupDataSource.addAndUpdateFollowup(
        followupId: followupId,
        customerId: customerId,
        sellerId: sellerId,
        productId: productId,
        status: status,
      );

      if (result['status'] == 'success') {
        return Right(result['message']);
      } else {
        return Left(
          ValidationFailure(
            result['message'] ?? 'Unknown error',
            result,
          ),
        );
      }
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<dynamic> getfollowupDetailsAndCancel({
    required String followupId,
    required bool isCancel,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await followupDataSource.getfollowupDetailsAndCancel(
        followupId: followupId,
        isCancel: isCancel,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> addNewFollwCustomer({
    required String name,
    required String type,
    required String phone,
    required String notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await followupDataSource.addNewFollwCustomer(
        name: name,
        type: type,
        phone: phone,
        notes: notes,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      } else {
        return Left(
          ValidationFailure(
            result['message'] ?? 'Unknown error',
            result,
          ),
        );
      }
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
