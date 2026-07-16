import '../../data/models/activity_summary_model.dart';
import '../repositories/admin_dashboard_repository.dart';

class GetActivitySummaryUsecase {
  final AdminDashboardRepository adminDashboardRepository;

  GetActivitySummaryUsecase({required this.adminDashboardRepository});

  Future<ActivitySummaryModel> call({
    String? dateFrom,
    String? dateTo,
  }) {
    return adminDashboardRepository.getActivitySummary(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
