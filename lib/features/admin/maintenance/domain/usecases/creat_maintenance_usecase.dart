import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/maintenance_repository.dart';

class CreatMaintenanceUsecase {
  final MaintenanceRepository maintenanceRepository;

  CreatMaintenanceUsecase({required this.maintenanceRepository});

  Future<Either<Failure, String>> call({
    String? maintenanceId,
    required String customerId,
    required String sellerId,
    required String description,
    required String receipDate,
    required String receiptTime,
    required List<File> files,
    required String status,
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
    );
  }
}
