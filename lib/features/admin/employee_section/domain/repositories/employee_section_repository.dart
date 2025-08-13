import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/failure.dart';

abstract class EmployeeRepository {
  Future<Either<Failure, bool>> creatEmployee({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String password,
    required String passwordConfirmation,
    required String hourWorkPrice,
    required String overtimeWorkPrice,
    required String numberOfWorkHours,
    required String startWorkTime,
    required XFile? documentImg,
    required XFile? employeeImg,
    required List<String> permissions,
  });

  Future<Either<Failure, String>> addPointsToEmployee({
    required String token,
    required String employeeId,
    required String points,
    required bool isAdd,
  });

  Future<Either<Failure, String>> paySalaryToEmployeeUsecase({
    required String token,
    required String employeeId,
    required String salary,
  });
}
