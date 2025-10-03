import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/check_model.dart';
import '../../data/models/general_checks_data_model.dart';

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
  });

  Future<Either<Failure, String>> editChecks({
    required bool isInComing,
    required String outgoingCheckId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
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

  Future<Either<Failure, String>> chashToBox(
      {required String boxId, required String checkId});
}
