import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/stock/data/models/product_details_model.dart';
import 'package:doctorbike/features/admin/stock/presentation/controllers/stock_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/connection/network_info.dart';
import '../../../../../../core/errors/failure.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../sales/data/models/product_model.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_datasource.dart';
import '../models/all_stock_products_model.dart';

class StockImplement implements StockRepository {
  final NetworkInfo networkInfo;
  final StockDatasource stockDataSource;

  StockImplement({required this.networkInfo, required this.stockDataSource});

  @override
  Future<List<AllStockProductsModel>> getAllStock({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.getAllStock(
          page: page, ifCombinations: ifCombinations, ifCloseouts: ifCloseouts);
      return result;
    } on ServerException catch (e) {
      Get.snackbar(
        "error".tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<ProductDetailsModel> getProductDetails(
      {required String productId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.getProductDetails(
        productId: productId,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> moveToArchive({
    required String productId,
    required bool isMove,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.moveToArchive(
        productId: productId,
        isMove: isMove,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get archived products
  @override
  Future<List<AllStockProductsModel>> getArchived() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.getArchived();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<List<ProductModel>> getCategories({required bool isProject}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.getCategories(isProject: isProject);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<List<AllStockProductsModel>> searchProducts(
      {required String name}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await stockDataSource.searchProducts(name: name);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> addCombination({
    required String productId,
    required RxList<NewCompositionModel> combinationId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await stockDataSource.addCombination(
        productId: productId,
        combinationList: combinationId,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Map<String, dynamic>> saveProductFull({
    required FormData formData,
    required bool isCreate,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await stockDataSource.saveProductFull(
        formData: formData,
        isCreate: isCreate,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
