import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ChangePassword {
  final AuthRepository authRepository;
  ChangePassword({required this.authRepository});

  Future<Either<Failure, bool>> call({
    required String token,
    required String oldPassword,
    required String password,
    required String confirmPassword,
  }) {
    return authRepository.changePassword(
      token: token,
      oldPassword: oldPassword,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
