import 'package:doctorbike/features/admin/admin_dashbord/data/models/main_dashboard_mata_model.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../employee_section/data/models/logs_model.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_datasource.dart';

class AdminDashboardImplement implements AdminDashboardRepository {
  final NetworkInfo networkInfo;
  final AdminDashboardDatasource adminDashboardDataSource;

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

  @override
  Future<MainDashboardDataModel> getAdminDashboardData() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await adminDashboardDataSource.getAdminDashboardData();
        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw NoConnectionFailure();
    }
  }
}
