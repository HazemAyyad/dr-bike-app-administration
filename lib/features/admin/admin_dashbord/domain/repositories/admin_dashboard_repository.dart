import '../../../employee_section/data/models/logs_model.dart';
import '../../data/models/activity_summary_model.dart';
import '../../data/models/main_dashboard_mata_model.dart';

abstract class AdminDashboardRepository {
  Future<List<LogsModel>> getAdminLogs();

  Future<ActivitySummaryModel> getActivitySummary({
    String? dateFrom,
    String? dateTo,
  });

  Future<MainDashboardDataModel> getAdminDashboardData();

  Future<DashboardUiPreferences> getDashboardUiPreferences();

  Future<DashboardUiPreferences> saveDashboardUiPreferences({
    required List<String> hiddenButtonKeys,
    required List<String> buttonOrderKeys,
  });
}

class DashboardUiPreferences {
  final List<String> hiddenButtonKeys;
  final List<String> buttonOrderKeys;

  const DashboardUiPreferences({
    this.hiddenButtonKeys = const [],
    this.buttonOrderKeys = const [],
  });
}
