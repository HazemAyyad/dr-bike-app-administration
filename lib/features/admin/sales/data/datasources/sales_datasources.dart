import 'dart:core';

import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';

class SalesDatasource {
  final ApiConsumer api;

  SalesDatasource({required this.api});

  // add profit sale
  Future<dynamic> addProfitSales({
    required String notes,
    required String totalCost,
  }) async {
    try {
      final response = await api.post(
        EndPoints.createProfitSale,
        data: {
          'notes': notes,
          'total_cost': totalCost,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['errors'] ?? {},
        ),
      );
    }
  }

  // get profit sales
  Future<List<ProfitSale>> getProfitSales() async {
    try {
      final response = await api.get(EndPoints.allProfitSales);
      return (response.data['profit_sales'] as List)
          .map((e) => ProfitSale.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get instant sales
  Future<List<InstantSalesModel>> getInstantSales() async {
    try {
      final response = await api.get(EndPoints.allInstantSales);
      return (response.data['instant_sales'] as List)
          .map((e) => InstantSalesModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get all products
  Future<List<ProductModel>> getAllProducts({required String endPoint}) async {
    try {
      final response =
          await api.get(endPoint.isNotEmpty ? endPoint : EndPoints.allProducts);
      return (response.data[endPoint == 'get/all/categories'
              ? 'categories'
              : endPoint == 'get/all/subcategories'
                  ? 'sub_categories'
                  : 'products'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add instant sale
  Future<dynamic> addInstantSales({
    required String productId,
    required String quantity,
    required String cost,
    required String discount,
    required String totalCost,
    required String note,
    required String type,
    required String projectId,
    required RxList<ItemModel> otherProducts,
  }) async {
    try {
      // final otherProductsMap = <String, dynamic>{};

      // for (int i = 1; i < otherProducts.length; i++) {
      //   otherProductsMap['other_products[$i][product_id]'] =
      //       otherProducts[i].selectedItem.value;
      //   otherProductsMap['other_products[$i][cost]'] =
      //       otherProducts[i].priceController.text;
      //   otherProductsMap['other_products[$i][quantity]'] =
      //       otherProducts[i].quantityController.text;
      //   otherProductsMap['other_products[$i][type]'] = 'normal';
      // }
      final otherProductsList = otherProducts
          .skip(1)
          .map((item) => {
                'product_id': item.selectedItem.value,
                'cost': item.priceController.text,
                'quantity': item.quantityController.text,
                'type':
                    item.selectedCustomersSellers.value ? 'project' : 'normal',
              })
          .toList();

      final response = await api.post(
        EndPoints.createInstantSale,
        data: {
          'product_id': productId,
          'quantity': quantity,
          'cost': cost,
          'discount': discount,
          'total_cost': totalCost,
          'notes': note,
          'type': type,
          'project_id': projectId,
          // ...otherProductsMap,
          'other_products': otherProductsList,
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get Invoice
  Future<InvoiceModel> getInvoice({required String invoiceId}) async {
    try {
      final response = await api.post(EndPoints.getInstantSaleInvoice,
          data: {'instant_sale_id': invoiceId});
      return InvoiceModel.fromJson(response.data['instant_sale_invoice']);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }
}
