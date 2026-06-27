import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class DeliverMaintenanceUsecase {
  final MaintenanceRepository maintenanceRepository;

  DeliverMaintenanceUsecase({required this.maintenanceRepository});

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String maintenanceId,
    double? laborCost,
    double? discount,
    double? paymentAmount,
    int? paymentBoxId,
  }) {
    return maintenanceRepository.deliverMaintenance(
      maintenanceId: maintenanceId,
      laborCost: laborCost,
      discount: discount,
      paymentAmount: paymentAmount,
      paymentBoxId: paymentBoxId,
    );
  }
}
