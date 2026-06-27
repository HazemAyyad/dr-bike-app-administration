import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/maintenance_product_model.dart';
import '../repositories/maintenance_repository.dart';

class SyncMaintenanceProductsUsecase {
  final MaintenanceRepository maintenanceRepository;

  SyncMaintenanceProductsUsecase({required this.maintenanceRepository});

  Future<Either<Failure, MaintenanceBillingModel>> call({
    required String maintenanceId,
    required List<MaintenanceProductModel> products,
    double? laborCost,
    double? discount,
  }) {
    return maintenanceRepository.syncMaintenanceProducts(
      maintenanceId: maintenanceId,
      products: products,
      laborCost: laborCost,
      discount: discount,
    );
  }
}
