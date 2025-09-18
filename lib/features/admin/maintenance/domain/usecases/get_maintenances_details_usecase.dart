import '../repositories/maintenance_repository.dart';

class GetMaintenancesDetailsUsecase {
  final MaintenanceRepository maintenanceRepository;

  GetMaintenancesDetailsUsecase({required this.maintenanceRepository});

  Future<dynamic> call({required String maintenanceId}) {
    return maintenanceRepository.getMaintenancesDetails(
      maintenanceId: maintenanceId,
    );
  }
}
