import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class GetMaintenanceDailySessionUsecase {
  final MaintenanceRepository maintenanceRepository;

  GetMaintenanceDailySessionUsecase({required this.maintenanceRepository});

  Future<Either<Failure, Map<String, dynamic>>> call() {
    return maintenanceRepository.getDailySessionCurrent();
  }
}
