import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/data/models/user_model.dart';
import 'dart:io';

abstract class CommonRepository {
  Future<Either<Failure, bool>> userProfile({
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
    File? employeeImage,
  });
  Future<UserModel> getUserData();
}
