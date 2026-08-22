import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../presentation/controllers/bills_controller.dart';

abstract class BillsRepository {
  Future<dynamic> getBills({required String page});

  Future<Either<Failure, String>> addBill({
    required String page,
    required String sellerId,
    String customerId,
    required List<BillModel> products,
    required String total,
  });

  Future<Either<Failure, String>> receivePurchase({
    required String billId,
    required List<Map<String, dynamic>> items,
    String? notes,
  });

  Future<Either<Failure, String>> finalizePurchase({
    required String billId,
    String initialPayment,
    String? boxId,
  });

  Future<Either<Failure, String>> payPurchase({
    required String billId,
    required String amount,
    required String boxId,
    String? note,
  });

  Future<Either<Failure, String>> paySupplierAccount({
    String sellerId,
    String customerId,
    required String amount,
    required String boxId,
    String? note,
    bool allocateOldestFirst,
    List<Map<String, dynamic>> allocations,
  });

  Future<dynamic> purchaseAccountOpenBills({
    String sellerId,
    String customerId,
    String? currency,
  });

  Future<Either<Failure, String>> createPurchaseReturn({
    String sellerId,
    String customerId,
    String? billId,
    required List<BillModel> products,
    required String total,
    required String resolution,
    String? refundBoxId,
    String? note,
  });

  Future<Either<Failure, String>> purchaseAmanat({
    required String amanatId,
    required String quantity,
    required String unitPrice,
  });

  Future<Either<Failure, String>> returnAmanat({
    required String amanatId,
    required String quantity,
    String? note,
  });

  Future<dynamic> purchaseTimeline({required String billId});

  Future<dynamic> purchasePriceIntelligence({
    required String productId,
    String? sellerId,
    String? customerId,
  });

  Future<dynamic> purchaseAmanatIndex({
    String? status,
    String? search,
  });

  Future<dynamic> purchaseDiscrepancies({
    String? type,
    String? search,
  });

  Future<Either<Failure, String>> uploadPurchaseAttachments({
    required String billId,
    required List<dynamic> files,
    String category,
    String? attachableType,
    String? attachableId,
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
