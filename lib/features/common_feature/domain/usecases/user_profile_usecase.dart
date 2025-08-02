import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/common_repositorie.dart';

class UserProfileUseCase {
  final CommonRepository commonRepository;
  UserProfileUseCase({required this.commonRepository});

  Future<Either<Failure, bool>> call({
    required String token,
    required String name,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  }) {
    return commonRepository.userProfile(
      token: token,
      name: name,
      phone: phone,
      subPhone: subPhone,
      city: city,
      address: address,
    );
  }
}
