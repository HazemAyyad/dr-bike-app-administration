import 'dart:developer' show log;

import 'package:dartz/dartz.dart';

import '../../../../core/connection/network_info.dart';
import '../../../../core/errors/expentions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../../../core/services/user_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_response_parser.dart';
import '../models/user_model.dart';

class AuthImplement implements AuthRepository {
  final NetworkInfo networkInfo;
  final AuthRemoteDatasource remoteDataSource;

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
  Future<Either<Failure, bool>> sendOtpToEmail({required String email}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.sendOtpToEmail(email: email);
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
  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otpCode,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await remoteDataSource.verifyOtp(
        email: email,
        otpCode: otpCode,
        password: password,
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
      final raw = result.data;
      if (raw is! Map) {
        return Left(ServerFailure('استجابة غير صالحة من السيرفر', {'message': raw}));
      }
      final data = Map<String, dynamic>.from(raw);

      log('AuthLogin: full response = $data', name: 'AuthLogin');

      if (!isLoginSuccessStatus(data['status'])) {
        return Left(
          ValidationFailure(
            data['message']?.toString() ?? 'فشل تسجيل الدخول',
            data,
          ),
        );
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        return Left(
          ServerFailure('لا يوجد رمز دخول (token) في الاستجابة', data),
        );
      }
      log(
        'AuthLogin: token prefix = ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
        name: 'AuthLogin',
      );

      await UserData.saveToken(token);

      final userModel = UserModel.fromJson(data);
      log('AuthLogin: parsed user name = ${userModel.user.name}', name: 'AuthLogin');
      log(
        'AuthLogin: employee ok id=${userModel.user.employee.id} userId=${userModel.user.employee.userId} points=${userModel.user.employee.points}',
        name: 'AuthLogin',
      );

      await UserData.saveUser(userModel);
      final userdata = await UserData.getSavedUser();
      if (userdata != null) {
        final permissionIds =
            userdata.employeePermissions.map((p) => p.permissionId).toList();
        employeePermissions.addAll(permissionIds);
        userType = userdata.user.type;
      }
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    } catch (e, st) {
      log('login unexpected error', error: e, stackTrace: st);
      return Left(
        ServerFailure(
          'تعذر إكمال تسجيل الدخول بعد استجابة السيرفر. جرّب تحديث الصفحة أو الدخول من التطبيق على الجوال.',
          null,
        ),
      );
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
        return const Right(true);
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
        return const Right(true);
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
