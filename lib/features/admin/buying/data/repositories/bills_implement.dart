import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:doctorbike/features/admin/buying/presentation/controllers/bills_controller.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/bills_repository.dart';
import '../datasources/bills_datasource.dart';

class BillsImplement implements BillsRepository {
  final NetworkInfo networkInfo;
  final BillsDatasource billsDataSource;

  BillsImplement({required this.networkInfo, required this.billsDataSource});

  // get bills
  @override
  Future<dynamic> getBills({required String page}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await billsDataSource.getBills(page: page);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  Either<Failure, String> _messageResult(dynamic result) {
    if (result is Map && result['status'] == 'success') {
      return Right((result['message'] ?? 'success').toString());
    }
    if (result is Map) {
      return Left(ValidationFailure(
        (result['message'] ?? 'Unknown error').toString(),
        Map<String, dynamic>.from(result),
      ));
    }
    return const Right('success');
  }

  @override
  Future<Either<Failure, String>> updatePurchaseDraft({
    required String billId,
    required String sellerId,
    String customerId = '',
    required List<BillModel> products,
    required String total,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) return Left(NoConnectionFailure());
    try {
      final result = await billsDataSource.updatePurchaseDraft(
        billId: billId,
        sellerId: sellerId,
        customerId: customerId,
        products: products,
        total: total,
        notes: notes,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> deletePurchaseDraft({
    required String billId,
  }) async {
    if (!await networkInfo.isConnected) return Left(NoConnectionFailure());
    try {
      return _messageResult(
        await billsDataSource.deletePurchaseDraft(billId: billId),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> receivePurchase({
    required String billId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.receivePurchase(
        billId: billId,
        items: items,
        notes: notes,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> finalizePurchase({
    required String billId,
    String initialPayment = '0',
    String? boxId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.finalizePurchase(
        billId: billId,
        initialPayment: initialPayment,
        boxId: boxId,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> payPurchase({
    required String billId,
    required String amount,
    required String boxId,
    String? note,
    List<dynamic> evidenceFiles = const [],
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.payPurchase(
        billId: billId,
        amount: amount,
        boxId: boxId,
        note: note,
        evidenceFiles: evidenceFiles.cast<MultipartFile>(),
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> paySupplierAccount({
    String sellerId = '',
    String customerId = '',
    required String amount,
    required String boxId,
    String? note,
    bool allocateOldestFirst = true,
    List<Map<String, dynamic>> allocations = const [],
    List<dynamic> evidenceFiles = const [],
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.paySupplierAccount(
        sellerId: sellerId,
        customerId: customerId,
        amount: amount,
        boxId: boxId,
        note: note,
        allocateOldestFirst: allocateOldestFirst,
        allocations: allocations,
        evidenceFiles: evidenceFiles.cast<MultipartFile>(),
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<dynamic> purchaseAccountOpenBills({
    String sellerId = '',
    String customerId = '',
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await billsDataSource.purchaseAccountOpenBills(
        sellerId: sellerId,
        customerId: customerId,
        currency: currency,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> createPurchaseReturn({
    String sellerId = '',
    String customerId = '',
    String? billId,
    required List<BillModel> products,
    required String total,
    required String resolution,
    String? refundBoxId,
    String? note,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.createPurchaseReturn(
        sellerId: sellerId,
        customerId: customerId,
        billId: billId,
        products: products,
        total: total,
        resolution: resolution,
        refundBoxId: refundBoxId,
        note: note,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<dynamic> getPurchaseReturns({String? status, String? search}) =>
      billsDataSource.getPurchaseReturns(status: status, search: search);

  @override
  Future<dynamic> getReturnablePurchaseBills() =>
      billsDataSource.getReturnablePurchaseBills();

  @override
  Future<dynamic> getPurchaseReturnAvailableItems({required String billId}) =>
      billsDataSource.getPurchaseReturnAvailableItems(billId);

  @override
  Future<dynamic> getPurchaseReturnDetails({required String returnId}) =>
      billsDataSource.getPurchaseReturnDetails(returnId);

  @override
  Future<dynamic> uploadPurchaseReturnAttachments({
    required String returnId,
    required List<MultipartFile> files,
  }) =>
      billsDataSource.uploadPurchaseReturnAttachments(
        returnId: returnId,
        files: files,
      );

  @override
  Future<List<int>> downloadPurchaseReturnPdf({required String returnId}) =>
      billsDataSource.downloadPurchaseReturnPdf(returnId);

  @override
  Future<dynamic> createPurchaseReturnDraft({
    String? billId,
    String? sellerId,
    String? customerId,
    String? currency,
    required List<Map<String, dynamic>> items,
    String? reason,
    String? notes,
  }) =>
      billsDataSource.createPurchaseReturnDraft(
        billId: billId,
        sellerId: sellerId,
        customerId: customerId,
        currency: currency,
        items: items,
        reason: reason,
        notes: notes,
      );

  @override
  Future<dynamic> getDirectPurchaseReturnOptions({String? search}) =>
      billsDataSource.getDirectPurchaseReturnOptions(search: search);

  @override
  Future<dynamic> purchaseReturnAction({
    required String returnId,
    required String action,
    Map<String, dynamic> data = const {},
  }) =>
      billsDataSource.purchaseReturnAction(
        returnId: returnId,
        action: action,
        data: data,
      );

  @override
  Future<Either<Failure, String>> purchaseAmanat({
    required String amanatId,
    required String quantity,
    required String unitPrice,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.purchaseAmanat(
        amanatId: amanatId,
        quantity: quantity,
        unitPrice: unitPrice,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> returnAmanat({
    required String amanatId,
    required String quantity,
    String? note,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.returnAmanat(
        amanatId: amanatId,
        quantity: quantity,
        note: note,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> resolvePurchaseIssue({
    required String billId,
    required String billItemId,
    required String issueType,
    required String resolution,
    required String quantity,
    String? negotiatedUnitPrice,
    String? financialAdjustment,
    String? reason,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.resolvePurchaseIssue(
        billId: billId,
        billItemId: billItemId,
        issueType: issueType,
        resolution: resolution,
        quantity: quantity,
        negotiatedUnitPrice: negotiatedUnitPrice,
        financialAdjustment: financialAdjustment,
        reason: reason,
        notes: notes,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<dynamic> purchaseTimeline({required String billId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await billsDataSource.purchaseTimeline(billId: billId);
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<dynamic> purchasePriceIntelligence({
    required String productId,
    String? sellerId,
    String? customerId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await billsDataSource.purchasePriceIntelligence(
        productId: productId,
        sellerId: sellerId,
        customerId: customerId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<dynamic> purchaseAmanatIndex({
    String? status,
    String? search,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await billsDataSource.purchaseAmanatIndex(
        status: status,
        search: search,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<dynamic> purchaseDiscrepancies({
    String? type,
    String? search,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await billsDataSource.purchaseDiscrepancies(
        type: type,
        search: search,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> uploadPurchaseAttachments({
    required String billId,
    required List<dynamic> files,
    String category = 'evidence',
    String? attachableType,
    String? attachableId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.uploadPurchaseAttachments(
        billId: billId,
        files: files.cast(),
        category: category,
        attachableType: attachableType,
        attachableId: attachableId,
      );
      return _messageResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // add bill
  @override
  Future<Either<Failure, String>> addBill({
    required String page,
    required String sellerId,
    String customerId = '',
    required List<BillModel> products,
    required String total,
    String initialPayment = '0',
    String? boxId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.addBill(
        page: page,
        sellerId: sellerId,
        customerId: customerId,
        products: products,
        total: total,
        initialPayment: initialPayment,
        boxId: boxId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<dynamic> getBillDetails({
    required String billId,
    required bool isDownload,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await billsDataSource.getBillDetails(
        billId: billId,
        isDownload: isDownload,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> cancelBill({required String billId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.cancelBill(billId: billId);
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // change product status
  @override
  Future<Either<Failure, String>> changeProductStatus({
    required String billId,
    required String productId,
    required String status,
    required String extraAmount,
    required String missingAmount,
    required String notCompatibleAmount,
    required String notCompatibleDescription,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeProductStatus(
        billId: billId,
        productId: productId,
        status: status,
        extraAmount: extraAmount,
        missingAmount: missingAmount,
        notCompatibleAmount: notCompatibleAmount,
        notCompatibleDescription: notCompatibleDescription,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> changeOneProductStatus({
    required String billId,
    required String productId,
    required String price,
    required bool isDeliver,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeOneProductStatus(
        billId: billId,
        productId: productId,
        price: price,
        isDeliver: isDeliver,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> changeReturnToDelivered(
      {required String returnPurchaseId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await billsDataSource.changeReturnToDelivered(
        returnPurchaseId: returnPurchaseId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
