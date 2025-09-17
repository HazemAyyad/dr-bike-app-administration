import '../repositories/maintenance_repository.dart';

class MaintenanceUsecase {
  final MaintenanceRepository maintenanceRepository;

  MaintenanceUsecase({required this.maintenanceRepository});

  Future<dynamic> call({required int tab}) {
    return maintenanceRepository.getMaintenances(tab: tab);
  }
}
