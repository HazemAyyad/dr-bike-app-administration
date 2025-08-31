import '../../data/models/dashbord_employee_details_model.dart';
import '../repositories/employee_dashbord_repository.dart';

class GetEmployeeDataUsecase {
  final EmployeeDashbordRepository employeeDashbordRepository;

  GetEmployeeDataUsecase({required this.employeeDashbordRepository});

  Future<DashbordEmployeeDetailsModel> call() {
    return employeeDashbordRepository.getEmployeeData();
  }
}
