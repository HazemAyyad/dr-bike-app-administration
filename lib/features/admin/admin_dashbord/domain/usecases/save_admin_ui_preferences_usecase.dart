import '../repositories/admin_dashboard_repository.dart';

class SaveAdminUiPreferencesUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  SaveAdminUiPreferencesUsecase({required this.adminDashboardRepository});

  Future<DashboardUiPreferences> call(
    List<String> hiddenButtonKeys, {
    required List<String> buttonOrderKeys,
    int? quickAccessCount,
    bool? showAttentionSection,
  }) {
    return adminDashboardRepository.saveDashboardUiPreferences(
      hiddenButtonKeys: hiddenButtonKeys,
      buttonOrderKeys: buttonOrderKeys,
      quickAccessCount: quickAccessCount,
      showAttentionSection: showAttentionSection,
    );
  }
}
