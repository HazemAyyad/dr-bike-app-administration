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
    String? receipDate,
    String? receiptTime,
    required List<File> files,
    required String status,
    double? laborCost,
    double? discount,
    String? editReason,
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
      editReason: editReason,
    );
  }
}
