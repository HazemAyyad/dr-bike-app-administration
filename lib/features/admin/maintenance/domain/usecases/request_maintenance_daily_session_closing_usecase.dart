import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class RequestMaintenanceDailySessionClosingUsecase {
  final MaintenanceRepository maintenanceRepository;

  RequestMaintenanceDailySessionClosingUsecase({
    required this.maintenanceRepository,
  });

  Future<Either<Failure, Map<String, dynamic>>> call({String? note}) {
    return maintenanceRepository.requestDailySessionClosing(note: note);
  }
}
