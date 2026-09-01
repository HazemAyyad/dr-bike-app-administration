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
    String? editReason,
    List<Map<String, dynamic>> serviceLines = const [],
    List<Map<String, dynamic>> additionalCharges = const [],
  }) {
    return maintenanceRepository.syncMaintenanceProducts(
      maintenanceId: maintenanceId,
      products: products,
      laborCost: laborCost,
      discount: discount,
      editReason: editReason,
      serviceLines: serviceLines,
      additionalCharges: additionalCharges,
    );
  }
}
