import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/connection/network_info.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/invoice_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/repositories/sales_repositores.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await salesDatasource.addProfitSales(
        notes: notes,
        totalCost: totalCost,
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
  Future<List<InstantSalesModel>> getInstantSales() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getInstantSales();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get all products
  @override
  Future<List<ProductModel>> getAllProducts({required String endPoint}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await salesDatasource.getAllProducts(endPoint: endPoint);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
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
      required String type,
      required String projectId,
      required RxList<ItemModel> otherProducts}) async {
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
        type: type,
        projectId: projectId,
        otherProducts: otherProducts,
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
}
