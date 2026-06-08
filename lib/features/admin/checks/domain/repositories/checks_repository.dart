import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/check_model.dart';
import '../../data/models/general_checks_data_model.dart';

class IncomingCheckBatchItem {
  const IncomingCheckBatchItem({
    required this.total,
    required this.dueDate,
    required this.currency,
    required this.checkId,
    required this.bankName,
    required this.notes,
    this.frontImage,
    this.backImage,
  });

  final String total;
  final DateTime dueDate;
  final String currency;
  final String checkId;
  final String bankName;
  final String notes;
  final XFile? frontImage;
  final XFile? backImage;
}

abstract class ChecksRepository {
  Future<Either<Failure, String>> addChecks({
    required bool isInComing,
    String? customerId,
    String? sellerId,
    required String total,
    required DateTime dueDate,
    required String currency,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  });

  Future<Either<Failure, String>> addIncomingChecksBatch({
    String? customerId,
    String? sellerId,
    required DateTime receivedAt,
    required List<IncomingCheckBatchItem> checks,
  });

  Future<Either<Failure, String>> editChecks({
    required bool isInComing,
    required String outgoingCheckId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    String? total,
    String? currency,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  });

  Future<dynamic> getChecks({required String endPoint});

  Future<GeneralChecksDataModel> generalChecksData();

  // Future<dynamic> generalOutgoingData({required bool isInComing});

  Future<Either<Failure, String>> cashedToPersonOrCashed({
    required bool isInComing,
    required String checkId,
    String? sellerId,
    String? customerId,
  });

  Future<List<SellerModel>> allCustomersSellers({required String endPoint});

  Future<Either<Failure, String>> returnCheck({
    required String checkId,
    required bool isInComing,
    required bool isCancel,
  });

  Future<Either<Failure, String>> chashToBox({
    required String boxId,
    required String checkId,
    required bool isInComing,
  });

  Future<Either<Failure, String>> deleteCheck({
    required String checkId,
    required bool isInComing,
  });
}
