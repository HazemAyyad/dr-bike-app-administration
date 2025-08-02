import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class Logout {
  final AuthRepository authRepository;
  Logout({required this.authRepository});

  Future<Either<Failure, bool>> call({required String token}) {
    return authRepository.logout(token: token);
  }
}
