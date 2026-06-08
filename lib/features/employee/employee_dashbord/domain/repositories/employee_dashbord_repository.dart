import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../../data/models/dashbord_employee_details_model.dart';

abstract class EmployeeDashbordRepository {
  Future<Either<Failure, String>> requestOverTimeOrLoan({
    required bool isOverTime,
    required String value,
  });
  Future<DashbordEmployeeDetailsModel> getEmployeeData();

  Future<EmployeeAttendanceHistoryResult> getMyAttendanceHistory({
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<Either<Failure, String>> changeEmployeeTaskToCompleted({
    required bool isSubTask,
    required int taskId,
    bool isOccurrence = false,
    int? occurrenceId,
    String? taskDate,
  });
}
