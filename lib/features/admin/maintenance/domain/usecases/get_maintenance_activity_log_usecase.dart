import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/maintenance_activity_log_model.dart';
import '../repositories/maintenance_repository.dart';

class GetMaintenanceActivityLogUsecase {
  final MaintenanceRepository maintenanceRepository;

  GetMaintenanceActivityLogUsecase({required this.maintenanceRepository});

  Future<Either<Failure, List<MaintenanceActivityLogModel>>> call({
    required String maintenanceId,
  }) {
    return maintenanceRepository.getActivityLog(maintenanceId: maintenanceId);
  }
}
