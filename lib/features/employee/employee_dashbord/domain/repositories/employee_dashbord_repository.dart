import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/dashbord_employee_details_model.dart';

abstract class EmployeeDashbordRepository {
  Future<Either<Failure, String>> requestOverTimeOrLoan({
    required bool isOverTime,
    required String value,
  });
  Future<DashbordEmployeeDetailsModel> getEmployeeData();
}
