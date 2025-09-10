import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../employee_section/data/models/logs_model.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_datasource.dart';

class AdminDashboardImplement implements AdminDashboardRepository {
  final NetworkInfo networkInfo;
  final AdminDashboardDataSource adminDashboardDataSource;

  AdminDashboardImplement(
      {required this.networkInfo, required this.adminDashboardDataSource});

  @override
  Future<List<LogsModel>> getAdminLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await adminDashboardDataSource.getAdminLogs();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw NoConnectionFailure();
    }
  }
}
