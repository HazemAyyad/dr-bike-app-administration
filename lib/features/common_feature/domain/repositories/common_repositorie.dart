import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';

abstract class CommonRepository {
  Future<Either<Failure, bool>> userProfile({
    required String token,
    required String name,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  });
}
