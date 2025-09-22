import 'package:dartz/dartz.dart';

import 'package:doctorbike/core/errors/failure.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../domain/repositories/boxes_repository.dart';
import '../datasources/boxes_datasource.dart';
import '../models/all_boxes_logs_model.dart';
import '../models/box_details_model.dart';
import '../models/get_shown_boxes_model.dart';

class BoxesImplement implements BoxesRepository {
  final NetworkInfo networkInfo;
  final BoxesDatasource boxesDatasource;

  BoxesImplement({required this.networkInfo, required this.boxesDatasource});

  // add box
  @override
  Future<Either<Failure, String>> addBox({
    required String boxName,
    required String total,
    required String currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await boxesDatasource.addBox(
        name: boxName,
        total: total,
        currency: currency,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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

  // get all boxes
  @override
  Future<List<GetShownBoxesModel>> getShownBoxes({required int screen}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await boxesDatasource.getShownBoxes(screen: screen);

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get all logs
  @override
  Future<List<BoxLogModel>> getAllBoxesLogs() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await boxesDatasource.getAllBoxesLogs();

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // transfer
  @override
  Future<Either<Failure, String>> transferBoxBalance({
    required String fromBoxId,
    required String toBoxId,
    required String total,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await boxesDatasource.transferBoxBalance(
        fromBoxId: fromBoxId,
        toBoxId: toBoxId,
        total: total,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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

  // box details
  @override
  Future<BoxDetailsModel> boxDetails({required String boxId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await boxesDatasource.boxDetails(boxId: boxId.toString());

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // add box balance
  @override
  Future<Either<Failure, String>> addBoxBalance(
      {required String boxId, required String total}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await boxesDatasource.addBoxBalance(
        boxId: boxId,
        total: total,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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

  // edit box
  @override
  Future<Either<Failure, String>> editBox({
    required String boxId,
    required String name,
    required String total,
    required String isShown,
    required String currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await boxesDatasource.editBox(
        name: name,
        isShown: isShown,
        boxId: boxId,
        total: total,
        currency: currency,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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
