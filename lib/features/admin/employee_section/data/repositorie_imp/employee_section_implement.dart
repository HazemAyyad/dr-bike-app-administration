import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/employee_section_repository.dart';
import '../datasources/employee_section_remote_datasource.dart';

class EmployeeImplement implements EmployeeRepository {
  final NetworkInfo networkInfo;
  final EmployeeDatasource employeeDatasource;

  EmployeeImplement(
      {required this.networkInfo, required this.employeeDatasource});

  // creat new employee
  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.creatEmployee(
        token: token,
        name: name,
        email: email,
        phone: phone,
        subPhone: subPhone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        hourWorkPrice: hourWorkPrice,
        overtimeWorkPrice: overtimeWorkPrice,
        numberOfWorkHours: numberOfWorkHours,
        startWorkTime: startWorkTime,
        documentImg: documentImg,
        employeeImg: employeeImg,
        permissions: permissions,
      );
      if (result['status'] == 'success') {
        return Right(true);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // add points or minus points
  @override
  Future<Either<Failure, String>> addPointsToEmployee({
    required String token,
    required String employeeId,
    required String points,
    required bool isAdd,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.addPointsToEmployee(
        token: token,
        employeeId: employeeId,
        points: points,
        isAdd: isAdd,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // pay salary to employee
  @override
  Future<Either<Failure, String>> paySalaryToEmployeeUsecase({
    required String token,
    required String employeeId,
    required String salary,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.paySalaryToEmployeeUsecase(
        token: token,
        employeeId: employeeId,
        salary: salary,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
