import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class OpenMaintenanceDailySessionUsecase {
  final MaintenanceRepository maintenanceRepository;

  OpenMaintenanceDailySessionUsecase({required this.maintenanceRepository});

  Future<Either<Failure, Map<String, dynamic>>> call() {
    return maintenanceRepository.openDailySession();
  }
}
