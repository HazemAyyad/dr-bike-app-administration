import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/connection/network_info.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/customer_product_price_history_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/invoice_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_price_update_result.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/suspended_instant_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/repositories/sales_repositores.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';

class SalesImplement implements SalesRepository {
  final NetworkInfo networkInfo;
  final SalesDatasource salesDatasource;

  SalesImplement({required this.networkInfo, required this.salesDatasource});

  // add profit sale
  @override
  Future<Either<Failure, String>> addProfitSales({
    required String notes,
    required String totalCost,
    String? buyerType,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? paymentBoxId,
    String? paymentBoxName,
    String? paymentBoxValue,
    XFile? image,
    XFile? video,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.addProfitSales(
        notes: notes,
        totalCost: totalCost,
        buyerType: buyerType,
        buyerId: buyerId,
        sellerId: sellerId,
        buyerName: buyerName,
        paymentBoxId: paymentBoxId,
        paymentBoxName: paymentBoxName,
        paymentBoxValue: paymentBoxValue,
        image: image,
        video: video,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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

  // get profit sales
  @override
  Future<List<ProfitSale>> getProfitSales() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getProfitSales();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get instant sales
  @override
  Future<List<InstantSalesModel>> getInstantSales({
    String? search,
    String sortDirection = 'desc',
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getInstantSales(
        search: search,
        sortDirection: sortDirection,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get all products
  @override
  Future<List<ProductModel>> getAllProducts({
    required String endPoint,
    String? customerId,
    String? sellerId,
    String? search,
    String? storeSectionId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getAllProducts(
        endPoint: endPoint,
        customerId: customerId,
        sellerId: sellerId,
        search: search,
        storeSectionId: storeSectionId,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, ProductPriceUpdateResult>> updateProductRetailPrice({
    required String productId,
    required double normailPrice,
    double? wholesalePrice,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final prices = await salesDatasource.updateProductRetailPrice(
        productId: productId,
        normailPrice: normailPrice,
        wholesalePrice: wholesalePrice,
      );
      return Right(prices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> addInstantSales(
      {required String productId,
      required String quantity,
      required String cost,
      required String discount,
      required String totalCost,
      required String note,
      List<Map<String, dynamic>> additionalNotes = const [],
      required String type,
      required String projectId,
      required RxList<ItemModel> otherProducts,
      required String buyerType,
      String? buyerId,
      String? sellerId,
      String? buyerName,
      String? paymentBoxId,
      String? paymentBoxName,
      String? paymentBoxValue,
      String? offerPackageId,
      List<Map<String, dynamic>>? cartOtherProducts,
      String? instantSaleId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.addInstantSales(
        productId: productId,
        quantity: quantity,
        cost: cost,
        discount: discount,
        totalCost: totalCost,
        note: note,
        additionalNotes: additionalNotes,
        type: type,
        projectId: projectId,
        otherProducts: otherProducts,
        buyerType: buyerType,
        buyerId: buyerId,
        sellerId: sellerId,
        buyerName: buyerName,
        paymentBoxId: paymentBoxId,
        paymentBoxName: paymentBoxName,
        paymentBoxValue: paymentBoxValue,
        offerPackageId: offerPackageId,
        cartOtherProducts: cartOtherProducts,
        instantSaleId: instantSaleId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
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
  Future<Either<Failure, String>> cancelInstantSale(
      {required String instantSaleId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await salesDatasource.cancelInstantSale(instantSaleId: instantSaleId);
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> cancelProfitSale(
      {required String profitSaleId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await salesDatasource.cancelProfitSale(profitSaleId: profitSaleId);
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> editInstantSale({
    required String instantSaleId,
    required String cost,
    required String quantity,
    required String totalCost,
    String? notes,
    String? paymentBoxValue,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.editInstantSale(
        instantSaleId: instantSaleId,
        cost: cost,
        quantity: quantity,
        totalCost: totalCost,
        notes: notes,
        paymentBoxValue: paymentBoxValue,
      );
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<InvoiceModel> getInvoice({required String invoiceId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getInvoice(invoiceId: invoiceId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<List<SuspendedInstantSaleModel>> getSuspendedInstantSales({
    String? search,
    int? createdByUserId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await salesDatasource.getSuspendedInstantSales(
        search: search,
        createdByUserId: createdByUserId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<int> getSuspendedInstantSalesCount() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await salesDatasource.getSuspendedInstantSalesCount();
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<SuspendedInstantSaleModel> getSuspendedInstantSale({
    required int id,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await salesDatasource.getSuspendedInstantSale(id: id);
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> suspendInstantSale({
    required String currentStep,
    required Map<String, dynamic> payload,
    int? suspendedInstantSaleId,
    String? note,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.suspendInstantSale(
        currentStep: currentStep,
        payload: payload,
        suspendedInstantSaleId: suspendedInstantSaleId,
        note: note,
      );
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, SuspendedInstantSaleModel>>
      addSuspendedInstantSaleNote({
    required int suspendedInstantSaleId,
    required String note,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.addSuspendedInstantSaleNote(
        suspendedInstantSaleId: suspendedInstantSaleId,
        note: note,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> completeSuspendedInstantSale({
    required int suspendedInstantSaleId,
    Map<String, dynamic>? payload,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.completeSuspendedInstantSale(
        suspendedInstantSaleId: suspendedInstantSaleId,
        payload: payload,
      );
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> cancelSuspendedInstantSale({
    required int suspendedInstantSaleId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.cancelSuspendedInstantSale(
        suspendedInstantSaleId: suspendedInstantSaleId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? 'success');
      }
      return Left(ValidationFailure(
        result['message'] ?? 'Unknown error',
        result,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<CustomerProductPriceHistory> getCustomerProductPriceHistory({
    String? personType,
    String? personId,
    required String productId,
    String? sizeColorId,
    int limit = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await salesDatasource.getCustomerProductPriceHistory(
        personType: personType,
        personId: personId,
        productId: productId,
        sizeColorId: sizeColorId,
        limit: limit,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
