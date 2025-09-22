import 'package:doctorbike/core/errors/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/profit_sale_model.dart';

abstract class SalesRepository {
  Future<Either<Failure, String>> addProfitSales({
    required String notes,
    required String totalCost,
  });
  Future<List<ProfitSale>> getProfitSales();

  Future<List<InstantSalesModel>> getInstantSales();

  Future<List<ProductModel>> getAllProducts();

  Future<Either<Failure, String>> addInstantSales({
    required String productId,
    required String quantity,
    required String cost,
    required String discount,
    required String totalCost,
    required String note,
    required String type,
    required String projectId,
    required RxList<ItemModel> otherProducts,
  });

  Future<InvoiceModel> getInvoice({required String invoiceId});
}
