import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/maintenance_invoice_model.dart';
import '../repositories/maintenance_repository.dart';

class GetMaintenanceInvoiceUsecase {
  final MaintenanceRepository maintenanceRepository;

  GetMaintenanceInvoiceUsecase({required this.maintenanceRepository});

  Future<Either<Failure, MaintenanceInvoiceModel>> call({
    required String maintenanceId,
  }) {
    return maintenanceRepository.getMaintenanceInvoice(
      maintenanceId: maintenanceId,
    );
  }
}
