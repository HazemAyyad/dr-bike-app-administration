import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;

import '../../../../../core/errors/failure.dart';
import '../../../sales/data/models/product_model.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../data/models/product_details_model.dart';
import '../../presentation/controllers/stock_controller.dart';

abstract class StockRepository {
  Future<List<AllStockProductsModel>> getAllStock({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
  });

  Future<ProductDetailsModel> getProductDetails({required String productId});

  /// خيارات الحجم (config + قاعدة البيانات + أحجام المنتج عند التعديل).
  Future<List<String>> getProductSizeOptions({String? productId});

  Future<Either<Failure, String>> moveToArchive({
    required String productId,
    required bool isMove,
  });

  Future<List<AllStockProductsModel>> getArchived();

  Future<List<ProductModel>> getCategories({required bool isProject});

  /// Main categories only (`get/all/categories`).
  Future<List<ProductModel>> getMainCategories();

  Future<List<AllStockProductsModel>> searchProducts({required String name});

  Future<Either<Failure, String>> addCombination({
    required String productId,
    required RxList<NewCompositionModel> combinationId,
  });

  /// إنشاء/تعديل منتج عبر API الكامل (multipart).
  Future<Map<String, dynamic>> saveProductFull({
    required FormData formData,
    required bool isCreate,
  });

  // Future<Either<Failure, String>> updateProduct({
  //   required String productId,
  //   required String name,
  //   required String description,
  //   required List<String> subCategories,
  //   required String minStock,
  //   required String normailPrice,
  //   required String discount,
  //   required String projectId,
  //   required DateTime rotationDate,
  //   required String minSalePrice,
  //   required String isSoldWithPaper,

  //   required String subSpecialTaskDescription,
  // });
}
