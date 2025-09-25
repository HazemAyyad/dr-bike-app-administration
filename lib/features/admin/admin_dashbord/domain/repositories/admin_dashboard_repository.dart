import '../../../employee_section/data/models/logs_model.dart';
import '../../data/models/main_dashboard_mata_model.dart';

abstract class AdminDashboardRepository {
  Future<List<LogsModel>> getAdminLogs();

  Future<MainDashboardDataModel> getAdminDashboardData();
}
