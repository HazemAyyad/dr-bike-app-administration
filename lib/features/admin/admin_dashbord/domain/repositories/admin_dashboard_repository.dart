import '../../../employee_section/data/models/logs_model.dart';

abstract class AdminDashboardRepository {
  Future<List<LogsModel>> getAdminLogs();
}
