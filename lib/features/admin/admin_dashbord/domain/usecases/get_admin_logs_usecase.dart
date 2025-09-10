import '../../../employee_section/data/models/logs_model.dart';
import '../repositories/admin_dashboard_repository.dart';

class GetAdminLogsUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  GetAdminLogsUsecase({required this.adminDashboardRepository});

  Future<List<LogsModel>> call() {
    return adminDashboardRepository.getAdminLogs();
  }
}
