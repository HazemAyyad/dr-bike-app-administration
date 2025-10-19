import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository authRepository;
  VerifyOtp({required this.authRepository});

  Future<Either<Failure, bool>> call({
    required String email,
    required String otpCode,
    required String password,
  }) {
    return authRepository.verifyOtp(
      email: email,
      otpCode: otpCode,
      password: password,
    );
  }
}
