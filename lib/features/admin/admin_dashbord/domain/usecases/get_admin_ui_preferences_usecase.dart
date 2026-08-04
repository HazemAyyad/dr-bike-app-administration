import '../repositories/admin_dashboard_repository.dart';

class GetAdminUiPreferencesUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  GetAdminUiPreferencesUsecase({required this.adminDashboardRepository});

  Future<List<String>> call() {
    return adminDashboardRepository.getHiddenDashboardButtonKeys();
  }
}
