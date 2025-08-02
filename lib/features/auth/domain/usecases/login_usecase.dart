import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository authRepository;

  Login({required this.authRepository});

  Future<Either<Failure, UserModel>> call({
    required String email,
    required String password,
    required String fcmToken,
  }) {
    return authRepository.login(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
  }
}
