import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/auth/data/models/user_model.dart';

import '../../../../core/connection/network_info.dart';
import '../../../../core/errors/expentions.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/common_repositorie.dart';
import '../datasources/common_datasource.dart';

class CommonImplement implements CommonRepository {
  final NetworkInfo networkInfo;
  final CommonDatasource commonDatasource;

  CommonImplement({required this.networkInfo, required this.commonDatasource});

  @override
  Future<Either<Failure, bool>> userProfile({
    required String name,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await commonDatasource.userProfile(
        name: name,
        phone: phone,
        subPhone: subPhone,
        city: city,
        address: address,
      );
      if (result['status'] == 'success') {
        return const Right(true);
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
  Future<UserModel> getUserData() async => await commonDatasource.getUserData();
}
