import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/maintenance_activity_log_model.dart';
import '../../data/models/maintenance_invoice_model.dart';
import '../../data/models/maintenance_product_model.dart';

abstract class MaintenanceRepository {
  Future<dynamic> getMaintenances({required int tab});

  Future<dynamic> getMaintenancesDetails({required String maintenanceId});

  Future<Either<Failure, Map<String, String>>> creatMaintenance({
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
  });

  Future<Either<Failure, MaintenanceBillingModel>> syncMaintenanceProducts({
    required String maintenanceId,
    required List<MaintenanceProductModel> products,
    double? laborCost,
    double? discount,
  });

  Future<Either<Failure, Map<String, dynamic>>> deliverMaintenance({
    required String maintenanceId,
    double? laborCost,
    double? discount,
    double? paymentAmount,
    int? paymentBoxId,
  });

  Future<Either<Failure, List<MaintenanceActivityLogModel>>> getActivityLog({
    required String maintenanceId,
  });

  Future<Either<Failure, MaintenanceInvoiceModel>> getMaintenanceInvoice({
    required String maintenanceId,
  });
}
