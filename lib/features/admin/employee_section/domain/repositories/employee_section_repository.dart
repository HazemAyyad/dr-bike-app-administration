import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_details_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/qr_generation_model.dart';
import '../../data/models/working_times_model.dart';
import '../entities/employee_entity.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeEntity>> getEmployees();

  Future<List<WorkingTimesModel>> getWorkingTimes();

  Future<List<FinancialDuesModel>> getFinancialDues();

  Future<FinancialDetailsModel> getfinancialDetails(
      {required String employeeId});

  Future<QrGenerationModel> qrGeneration();

  Future<Either<Failure, String>> qrScan({required String qrData});

  Future<EmployeeDetailsModel> getEmployeeDetails({required String employeeId});

  Future<Either<Failure, String>> creatEmployee({
    String? employeeId,
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
    required String employeeId,
    required String points,
    required bool isAdd,
  });

  Future<Either<Failure, String>> paySalaryToEmployeeUsecase({
    required String employeeId,
    required String salary,
  });
}
