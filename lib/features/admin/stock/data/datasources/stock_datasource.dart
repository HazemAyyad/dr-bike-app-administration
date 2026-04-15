import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../sales/data/models/product_model.dart';
import '../../presentation/controllers/stock_controller.dart';
import '../models/all_stock_products_model.dart';
import '../models/product_details_model.dart';

class StockDatasource {
  final ApiConsumer api;

  StockDatasource({required this.api});

  // Get all products
  Future<List<AllStockProductsModel>> getAllStock({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
  }) async {
    try {
      final response = await api.get(
          ifCombinations
              ? EndPoints.getAllCombinations
              : ifCloseouts
                  ? EndPoints.getUnarchivedCloseouts
                  : EndPoints.getProductsList,
          queryParameters: {'page': page});
      final key = ifCombinations
          ? 'combinations'
          : ifCloseouts
              ? 'closeoutes'
              : 'products';
      return mapListFromResponseKey(
        response.data,
        key,
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
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

  // get product details
  Future<ProductDetailsModel> getProductDetails({
    required String productId,
  }) async {
    try {
      final response = await api.post(EndPoints.getProductDetails,
          queryParameters: {'product_id': productId});
      final raw = response.data;
      final productMap = raw is Map ? asMap((raw as Map)['product']) : <String, dynamic>{};
      return ProductDetailsModel.fromJson(productMap);
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

  // move to archive
  Future<Either<Failure, String>> moveToArchive({
    required String productId,
    required bool isMove,
  }) async {
    try {
      final response = await api.post(
          isMove ? EndPoints.archiveCloseout : EndPoints.addProductToCloseouts,
          queryParameters: {
            if (!isMove) 'product_id': productId,
            if (isMove) 'closeout_id': productId
          });
      return Right(response.data['message']);
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

  // get archived products
  Future<List<AllStockProductsModel>> getArchived() async {
    try {
      final response = await api.get(EndPoints.getArchivedCloseouts);
      return mapListFromResponseKey(
        response.data,
        'closeoutes',
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
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

  // get categories
  Future<List<ProductModel>> getCategories({required bool isProject}) async {
    try {
      final response = await api
          .get(isProject ? EndPoints.getProjects : EndPoints.getCategories);
      final key = isProject ? 'projects' : 'sub_categories';
      return mapListFromResponseKey(
        response.data,
        key,
        (Map<String, dynamic> m) => ProductModel.fromJson(m),
      );
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

  // search products
  Future<List<AllStockProductsModel>> searchProducts(
      {required String name}) async {
    try {
      final response = await api
          .post(EndPoints.searchProducts, queryParameters: {'name': name});
      return mapListFromResponseKey(
        response.data,
        'products',
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
    } on DioException catch (e) {
      Get.snackbar(
        "error".tr,
        e.response?.data['message'] ?? 'Unknown error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

  // add Combination
  Future<Either<Failure, String>> addCombination({
    required String productId,
    required RxList<NewCompositionModel> combinationList,
  }) async {
    try {
      final combinationListMap = <String, dynamic>{};

      for (int i = 0; i < combinationList.length; i++) {
        combinationListMap['added_products[$i][product_id]'] =
            combinationList[i].productIdController.text;
        combinationListMap['added_products[$i][quantity]'] =
            combinationList[i].quantityController.text;
      }
      final response = await api.post(
        EndPoints.addCombination,
        data: {'main_product_id': productId, ...combinationListMap},
        isFormData: true,
      );
      return Right(response.data['message']);
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

  /// `create/product` أو `update/product/full` — الجسم جاهز كـ [FormData].
  Future<Map<String, dynamic>> saveProductFull({
    required FormData formData,
    required bool isCreate,
  }) async {
    try {
      final response = await api.post(
        isCreate ? EndPoints.createProductFull : EndPoints.updateProductFull,
        data: formData,
      );
      final raw = response.data;
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid response',
            status: 500,
            data: {},
          ),
        );
      }
      final map = Map<String, dynamic>.from(raw);
      if (map['status']?.toString() == 'error') {
        throw ServerException(
          ErrorModel(
            errorMessage: map['message']?.toString() ?? 'Error',
            status: 422,
            data: map,
          ),
        );
      }
      return map;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map ? (data['message']?.toString() ?? 'Unknown error') : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? Map<String, dynamic>.from(data) : {},
        ),
      );
    }
  }
}
