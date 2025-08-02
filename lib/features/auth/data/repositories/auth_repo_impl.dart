import 'package:dartz/dartz.dart';

import '../../../../core/connection/network_info.dart';
import '../../../../core/errors/expentions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/user_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthImplement implements AuthRepository {
  final NetworkInfo networkInfo;
  final AuthRemoteDataSource remoteDataSource;

  AuthImplement({required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (result['status'] == 'success') {
        return Right(true);
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
  Future<Either<Failure, bool>> sendOtpToEmail({required String email}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.sendOtpToEmail(email: email);
      if (result['status'] == 'success') {
        return Right(true);
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
  Future<Either<Failure, bool>> verifyOtp(
      {required String email, required String otpCode}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await remoteDataSource.verifyOtp(email: email, otpCode: otpCode);

      if (result['status'] == 'success') {
        return Right(true);
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
  Future<Either<Failure, UserModel>> login({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
      final data = Map<String, dynamic>.from(result.data);

      if (data['status'] == 'success') {
        await UserData.saveToken(data['token']);
        await UserData.saveUser(UserModel.fromJson(data['user']));
        return Right(UserModel.fromJson(data));
      }
      return Left(
        ValidationFailure(
          data['message'] ?? 'Unknown error',
          data,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, bool>> logout({required String token}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.logout(token: token);
      if (result['status'] == 'success') {
        return Right(true);
      } else {
        return Left(
          ValidationFailure(
            result['message'] ?? 'Unknown error',
            result ?? {},
          ),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // @override
  // Future<Either<Failure, String>> requestToChangePassword(
  //     {required String email}) async {
  //   if (await networkInfo.isConnected) {
  //     try {
  //       final res = await remoteDataSource.requesToChangePassword(email: email);
  //       if (res['status'] == true || res['status'] == 'true') {
  //         return Right(res['message']);
  //       } else {
  //         return Left(Failure(errMessage: res['message']));
  //       }
  //     } on Exception catch (_) {
  //       return Left(Failure(errMessage: "Failed"));
  //     }
  //   } else {
  //     return Left(Failure(errMessage: 'No Internet Connection'));
  //   }
  // }

  // @override
  // Future<Either<Failure, bool>> verifyChangePassword(
  //     {required String email, required String otpCode}) async {
  //   if (await networkInfo.isConnected) {
  //     try {
  //       final result = await remoteDataSource.verifyChangePassword(
  //           email: email, otpCode: otpCode);
  //       if (result['status'] == 'true') {
  //         return Right(true);
  //       } else {
  //         return Left(
  //             Failure(errMessage: "Invalid OTP code. Please try again."));
  //       }
  //     } on ServerException catch (e) {
  //       return Left(Failure(errMessage: e.errorModel.errorMessage));
  //     } catch (e) {
  //       return Left(Failure(errMessage: 'Unexpected error occurred.'));
  //     }
  //   } else {
  //     return Left(Failure(errMessage: 'No Internet Connection'));
  //   }
  // }
  @override
  Future<Either<Failure, bool>> changePassword({
    required String token,
    required String oldPassword,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.changePassword(
        token: token,
        oldPassword: oldPassword,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (result['status'] == 'success') {
        return Right(true);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result ?? {},
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
