import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';

abstract class MaintenanceRepository {
  Future<dynamic> getMaintenances({required int tab});

  Future<dynamic> getMaintenancesDetails({required String maintenanceId});

  Future<Either<Failure, String>> creatMaintenance({
    String? maintenanceId,
    required String customerId,
    required String sellerId,
    required String description,
    required String receipDate,
    required String receiptTime,
    required List<File> files,
    required String status,
  });
}
