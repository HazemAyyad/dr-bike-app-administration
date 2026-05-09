import '../../data/models/qr_history_model.dart';
import '../repositories/employee_section_repository.dart';

class QrHistoryUsecase {
  final EmployeeRepository employeeRepository;

  QrHistoryUsecase({required this.employeeRepository});

  Future<QrHistoryResult> call({int page = 1, int perPage = 20}) {
    return employeeRepository.qrHistory(page: page, perPage: perPage);
  }
}

