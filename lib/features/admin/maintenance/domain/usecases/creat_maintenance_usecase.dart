import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class CreatMaintenanceUsecase {
  final MaintenanceRepository maintenanceRepository;

  CreatMaintenanceUsecase({required this.maintenanceRepository});

  Future<Either<Failure, Map<String, String>>> call({
    String? maintenanceId,
    required String customerId,
    required String sellerId,
    required String description,
    required String receipDate,
    required String receiptTime,
    required List<File> files,
    required String status,
    double? laborCost,
    double? discount,
  }) {
    return maintenanceRepository.creatMaintenance(
      maintenanceId: maintenanceId,
      customerId: customerId,
      sellerId: sellerId,
      description: description,
      receipDate: receipDate,
      receiptTime: receiptTime,
      files: files,
      status: status,
      laborCost: laborCost,
      discount: discount,
    );
  }
}
