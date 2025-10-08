import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, bool>> sendOtpToEmail({required String email});

  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otpCode,
    required String password,
  });

  Future<Either<Failure, UserModel>> login({
    required String email,
    required String password,
    required String fcmToken,
  });

  Future<Either<Failure, bool>> logout({required String token});

  // Future<Either<Failure, String>> requestToChangePassword(
  //     {required String email});

  // Future<Either<Failure, bool>> verifyChangePassword(
  //     {required String email, required String otpCode});

  Future<Either<Failure, bool>> changePassword({
    required String token,
    required String oldPassword,
    required String password,
    required String confirmPassword,
  });
}
