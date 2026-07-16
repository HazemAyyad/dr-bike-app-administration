import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class DeleteMaintenanceUsecase {
  final MaintenanceRepository maintenanceRepository;

  DeleteMaintenanceUsecase({required this.maintenanceRepository});

  Future<Either<Failure, String>> call({required String maintenanceId}) {
    return maintenanceRepository.deleteMaintenance(
      maintenanceId: maintenanceId,
    );
  }
}
