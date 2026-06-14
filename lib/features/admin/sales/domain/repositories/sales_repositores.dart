import 'package:doctorbike/core/errors/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_price_update_result.dart';
import '../../data/models/profit_sale_model.dart';
import '../../data/models/suspended_instant_sale_model.dart';

abstract class SalesRepository {
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
  });
  Future<List<ProfitSale>> getProfitSales();

  Future<List<InstantSalesModel>> getInstantSales({
    String? search,
    String sortDirection = 'desc',
  });

  Future<List<ProductModel>> getAllProducts({required String endPoint});

  Future<Either<Failure, ProductPriceUpdateResult>> updateProductRetailPrice({
    required String productId,
    required double normailPrice,
    double? wholesalePrice,
  });

  Future<Either<Failure, String>> addInstantSales({
    required String productId,
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
    String? instantSaleId,
  });

  Future<Either<Failure, String>> cancelInstantSale(
      {required String instantSaleId});

  Future<Either<Failure, String>> cancelProfitSale(
      {required String profitSaleId});

  Future<Either<Failure, String>> editInstantSale({
    required String instantSaleId,
    required String cost,
    required String quantity,
    required String totalCost,
    String? notes,
    String? paymentBoxValue,
  });

  Future<InvoiceModel> getInvoice({required String invoiceId});

  Future<List<SuspendedInstantSaleModel>> getSuspendedInstantSales({
    String? search,
    int? createdByUserId,
  });

  Future<int> getSuspendedInstantSalesCount();

  Future<SuspendedInstantSaleModel> getSuspendedInstantSale({required int id});

  Future<Either<Failure, String>> suspendInstantSale({
    required String currentStep,
    required Map<String, dynamic> payload,
    int? suspendedInstantSaleId,
  });

  Future<Either<Failure, String>> completeSuspendedInstantSale({
    required int suspendedInstantSaleId,
    Map<String, dynamic>? payload,
  });

  Future<Either<Failure, String>> cancelSuspendedInstantSale({
    required int suspendedInstantSaleId,
  });
}
