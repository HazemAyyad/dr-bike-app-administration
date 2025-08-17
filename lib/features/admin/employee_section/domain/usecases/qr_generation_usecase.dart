import '../../data/models/qr_generation_model.dart';
import '../repositories/employee_section_repository.dart';

class QrGenerationUsecase {
  final EmployeeRepository employeeRepository;

  QrGenerationUsecase({required this.employeeRepository});

  Future<QrGenerationModel> call() {
    return employeeRepository.qrGeneration();
  }
}
