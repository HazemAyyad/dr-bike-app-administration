import '../repositories/admin_dashboard_repository.dart';

class SaveAdminUiPreferencesUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  SaveAdminUiPreferencesUsecase({required this.adminDashboardRepository});

  Future<List<String>> call(List<String> hiddenButtonKeys) {
    return adminDashboardRepository.saveHiddenDashboardButtonKeys(
      hiddenButtonKeys,
    );
  }
}
