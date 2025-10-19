import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class Register {
  final AuthRepository authRepository;
  Register({required this.authRepository});

  Future<Either<Failure, bool>> call({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return authRepository.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
