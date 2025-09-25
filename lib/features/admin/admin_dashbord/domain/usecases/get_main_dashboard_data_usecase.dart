import '../../data/models/main_dashboard_mata_model.dart';
import '../repositories/admin_dashboard_repository.dart';

class GetMainDashboardDataUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  GetMainDashboardDataUsecase({required this.adminDashboardRepository});

  Future<MainDashboardDataModel> call() {
    return adminDashboardRepository.getAdminDashboardData();
  }
}
