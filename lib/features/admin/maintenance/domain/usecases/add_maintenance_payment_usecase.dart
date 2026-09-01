import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class AddMaintenancePaymentUsecase {
  const AddMaintenancePaymentUsecase({required this.maintenanceRepository});

  final MaintenanceRepository maintenanceRepository;

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String maintenanceId,
    required double amount,
    String? note,
  }) {
    return maintenanceRepository.addMaintenancePayment(
      maintenanceId: maintenanceId,
      amount: amount,
      note: note,
    );
  }
}
