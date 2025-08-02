import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class SendOtpToEmail {
  final AuthRepository authRepository;
  SendOtpToEmail({required this.authRepository});

  Future<Either<Failure, bool>> call({
    required String email,
  }) {
    return authRepository.sendOtpToEmail(
      email: email,
    );
  }
}
