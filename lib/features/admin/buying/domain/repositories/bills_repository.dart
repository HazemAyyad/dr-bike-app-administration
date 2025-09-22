import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../presentation/controllers/bills_controller.dart';

abstract class BillsRepository {
  Future<dynamic> getBills({required String page});

  Future<Either<Failure, String>> addBill({
    required String page,
    required String sellerId,
    required List<BillModel> products,
    required String total,
  });

  Future<dynamic> getBillDetails({
    required String billId,
    required bool isDownload,
  });

  Future<Either<Failure, String>> cancelBill({required String billId});

  Future<Either<Failure, String>> changeProductStatus({
    required String billId,
    required String productId,
    required String status,
    required String extraAmount,
    required String missingAmount,
    required String notCompatibleAmount,
    required String notCompatibleDescription,
  });

  Future<Either<Failure, String>> changeOneProductStatus({
    required String billId,
    required String productId,
    required String price,
    required bool isDeliver,
  });

  Future<Either<Failure, String>> changeReturnToDelivered({
    required String returnPurchaseId,
  });
}
