import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../sales/data/models/product_model.dart';
import '../../presentation/controllers/stock_controller.dart';
import '../models/all_stock_products_model.dart';
import '../models/stock_products_page_result.dart';
import '../models/product_details_model.dart';
import '../models/product_tag_model.dart';
import '../../domain/product_location_utils.dart';
import '../../domain/stock_product_filters.dart';
import '../models/offer_package_model.dart';
import '../models/products_by_tag_result.dart';
import '../models/products_by_location_result.dart';
import '../models/product_stock_movement_model.dart';
import '../models/store_section_model.dart';
class StockDatasource {
  final ApiConsumer api;

  StockDatasource({required this.api});

  Future<Uint8List> exportProductsCsv() async {
    try {
      final response = await api.get(
        EndPoints.exportProductsCsv,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data is Uint8List) {
        return data;
      }
      if (data is List<int>) {
        return Uint8List.fromList(data);
      }
      throw ServerException(
        ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> importProductsCsv(String filePath) async {
    return _sendProductsCsv(
      endpoint: EndPoints.importProductsCsv,
      filePath: filePath,
    );
  }

  Future<Map<String, dynamic>> previewImportProductsCsv(String filePath) async {
    return _sendProductsCsv(
      endpoint: EndPoints.previewImportProductsCsv,
      filePath: filePath,
    );
  }

  Future<Map<String, dynamic>> _sendProductsCsv({
    required String endpoint,
    required String filePath,
  }) async {
    try {
      final response = await api.post(
        endpoint,
        data: {
          'file': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split(Platform.pathSeparator).last,
          ),
        },
        isFormData: true,
      );
      final raw = response.data;
      if (raw is Map) {
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
      }
      throw ServerException(
        ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  // Get all products
  Future<StockProductsPageResult> getAllStock({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
    StockProductFilters? filters,
    int perPage = 15,
  }) async {
    try {
      final queryParams = ifCombinations || ifCloseouts
          ? <String, dynamic>{'page': page}
          : {
              ...?filters?.toQueryParams(page: page, perPage: perPage),
              if (filters == null) 'page': page,
            };

      final response = await api.get(
          ifCombinations
              ? EndPoints.getAllCombinations
              : ifCloseouts
                  ? EndPoints.getUnarchivedCloseouts
                  : EndPoints.getProductsList,
          queryParameters: queryParams);
      final key = ifCombinations
          ? 'combinations'
          : ifCloseouts
              ? 'closeoutes'
              : 'products';
      final raw = response.data;
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final products = mapListFromResponseKey(
        map,
        key,
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
      final p = map['pagination'];
      final pg = p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{};
      return StockProductsPageResult(
        products: products,
        currentPage: asInt(pg['current_page'], page),
        lastPage: asInt(pg['last_page'], 1),
        total: asInt(pg['total'], products.length),
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

  Future<List<String>> getSizeOptionPresets() async {
    try {
      final response = await api.get(EndPoints.stockSizeOptionPresets);
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        return [];
      }
      final list = raw['sizes'];
      if (list is! List) return [];
      return list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<List<String>> saveSizeOptionPresets(List<String> sizes) async {
    try {
      final response = await api.put(
        EndPoints.stockSizeOptionPresets,
        data: {'sizes': sizes},
      );
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw is Map
                ? (raw['message'] ?? 'Unknown error')
                : 'Unknown error',
            status: 500,
            data: raw is Map ? raw : {},
          ),
        );
      }
      final list = raw['sizes'];
      if (list is! List) return sizes;
      return list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<List<String>> getProductSizeOptions({String? productId}) async {
    try {
      final response = await api.get(
        EndPoints.productSizeOptions,
        queryParameters: {
          if (productId != null && productId.isNotEmpty)
            'product_id': productId,
        },
      );
      final raw = response.data;
      if (raw is! Map) {
        return [];
      }
      final list = raw['sizes'];
      if (list is! List) {
        return [];
      }
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
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
      final productMap =
          raw is Map ? asMap(raw['product']) : <String, dynamic>{};
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

  /// Main categories (`categories` key).
  Future<List<ProductModel>> getMainCategories() async {
    try {
      final response = await api.get(EndPoints.categories);
      return mapListFromResponseKey(
        response.data,
        'categories',
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
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? Map<String, dynamic>.from(data) : {},
        ),
      );
    }
  }

  Future<List<ProductTagModel>> getProductTags({
    bool includeInactive = false,
  }) async {
    try {
      final response = await api.get(
        EndPoints.productTagsList,
        queryParameters: {
          if (includeInactive) 'include_inactive': '1',
        },
      );
      return mapListFromResponseKey(
        response.data,
        'tags',
        (Map<String, dynamic> m) => ProductTagModel.fromJson(m),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<ProductsByTagResult> getProductsByTag({
    required String tagId,
    required int page,
  }) async {
    try {
      final response = await api.get(
        EndPoints.productsByTag,
        queryParameters: {'tag_id': tagId, 'page': page},
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
      ProductTagModel? tag;
      final tagMap = map['tag'];
      if (tagMap is Map) {
        tag = ProductTagModel.fromJson(Map<String, dynamic>.from(tagMap));
      }
      final products = mapListFromResponseKey(
        map,
        'products',
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
      final p = map['pagination'];
      final pg = p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{};
      return ProductsByTagResult(
        tag: tag,
        products: products,
        currentPage: asInt(pg['current_page'], 1),
        lastPage: asInt(pg['last_page'], 1),
        total: asInt(pg['total'], products.length),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<ProductTagModel> createProductTag({
    required String name,
    required String color,
  }) async {
    try {
      final response = await api.post(
        EndPoints.productTagsCreate,
        data: {'name': name, 'color': color},
      );
      final raw = response.data;
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      final tagMap = asMap((raw)['tag']);
      return ProductTagModel.fromJson(tagMap);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<void> updateProductTag({
    required String id,
    String? name,
    String? color,
  }) async {
    try {
      final data = <String, dynamic>{'tag_id': id};
      if (name != null) {
        data['name'] = name;
      }
      if (color != null) {
        data['color'] = color;
      }
      await api.post(EndPoints.productTagsUpdate, data: data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<List<OfferPackageModel>> getOfferPackages(
      {required String tab}) async {
    try {
      final response = await api.get(
        EndPoints.offerPackages,
        queryParameters: {'tab': tab},
      );
      return mapListFromResponseKey(
        response.data,
        'packages',
        (Map<String, dynamic> m) => OfferPackageModel.fromJson(m),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<List<OfferPackageModel>> getOfferPackagesForSale() async {
    try {
      final response = await api.get(EndPoints.offerPackagesForSale);
      return mapListFromResponseKey(
        response.data,
        'packages',
        (Map<String, dynamic> m) => OfferPackageModel.fromJson(m),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<OfferPackageModel> getOfferPackageDetails({required String id}) async {
    try {
      final response = await api.get(
        EndPoints.offerPackagesShow,
        queryParameters: {'offer_package_id': id},
      );
      final raw = response.data;
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      final pkg = asMap((raw)['package']);
      return OfferPackageModel.fromJson(pkg);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<String> saveOfferPackage({
    required String name,
    required double price,
    required int packageQuantity,
    required List<Map<String, int>> items,
    String? offerPackageId,
    String? imagePath,
  }) async {
    try {
      final isCreate = offerPackageId == null || offerPackageId.isEmpty;
      final endpoint =
          isCreate ? EndPoints.offerPackages : EndPoints.offerPackagesUpdate;

      final body = <String, dynamic>{
        'name': name,
        'price': price,
        'package_quantity': packageQuantity,
        if (!isCreate) 'offer_package_id': offerPackageId,
      };

      for (var i = 0; i < items.length; i++) {
        body['items[$i][product_id]'] = items[i]['product_id'];
        body['items[$i][quantity]'] = items[i]['quantity'];
      }

      final Response response;
      if (imagePath != null && imagePath.isNotEmpty) {
        response = await api.post(
          endpoint,
          data: {
            ...body,
            'image': await MultipartFile.fromFile(imagePath),
          },
          isFormData: true,
        );
      } else {
        response = await api.post(endpoint, data: body);
      }

      final raw = response.data;
      if (raw is Map && raw['status'] == 'success') {
        return raw['message']?.toString() ?? 'success';
      }
      final message =
          raw is Map ? (raw['message'] ?? 'Unknown error') : 'Unknown error';
      throw ServerException(
        ErrorModel(
          errorMessage: message.toString(),
          status: 500,
          data: raw is Map ? raw : {},
        ),
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<String> deleteOfferPackage({required String id}) async {
    try {
      final response = await api.post(
        EndPoints.offerPackagesDelete,
        data: {'offer_package_id': id},
      );
      final raw = response.data;
      if (raw is Map && raw['status'] == 'success') {
        return raw['message']?.toString() ?? 'success';
      }
      throw ServerException(
        ErrorModel(
          errorMessage: raw is Map
              ? (raw['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: 500,
          data: raw is Map ? raw : {},
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<void> deactivateProductTag({required String id}) async {
    try {
      await api.post(
        EndPoints.productTagsDeactivate,
        data: {'tag_id': id},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<List<StoreSectionModel>> getStoreSections({
    bool includeInactive = false,
  }) async {
    try {
      final response = await api.get(
        EndPoints.storeSectionsList,
        queryParameters: {
          if (includeInactive) 'include_inactive': '1',
        },
      );
      return mapListFromResponseKey(
        response.data,
        'sections',
        (Map<String, dynamic> m) => StoreSectionModel.fromJson(m),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<ProductsByLocationResult> getProductsByLocation({
    required String sectionId,
    required int page,
  }) async {
    try {
      final response = await api.get(
        EndPoints.productsByLocation,
        queryParameters: {
          'section_id': sectionId,
          'page': page,
        },
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
      StoreSectionModel? section;
      final sectionMap = map['section'];
      if (sectionMap is Map) {
        section = StoreSectionModel.fromJson(Map<String, dynamic>.from(sectionMap));
      }
      final products = mapListFromResponseKey(
        map,
        'products',
        (Map<String, dynamic> m) => AllStockProductsModel.fromJson(m),
      );
      final p = map['pagination'];
      final pg = p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{};
      return ProductsByLocationResult(
        section: section,
        products: products,
        currentPage: asInt(pg['current_page'], 1),
        lastPage: asInt(pg['last_page'], 1),
        total: asInt(pg['total'], products.length),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<StoreSectionModel> createStoreSection({
    required String name,
    String? description,
    int sortOrder = 0,
  }) async {
    try {
      final response = await api.post(
        EndPoints.storeSectionsCreate,
        data: {
          'name': name,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'sort_order': sortOrder,
        },
      );
      final raw = response.data;
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      final sectionMap = raw['section'];
      if (sectionMap is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      return StoreSectionModel.fromJson(Map<String, dynamic>.from(sectionMap));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<void> deactivateStoreSection({required String id}) async {
    try {
      await api.post(
        EndPoints.storeSectionsDeactivate,
        data: {'section_id': id},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<StoreSectionModel> updateStoreSection({
    required String id,
    String? name,
    String? description,
    int? sortOrder,
  }) async {
    try {
      final response = await api.post(
        EndPoints.storeSectionsUpdate,
        data: {
          'section_id': id,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (sortOrder != null) 'sort_order': sortOrder,
        },
      );
      final raw = response.data;
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      final sectionMap = raw['section'];
      if (sectionMap is! Map) {
        throw ServerException(
          ErrorModel(errorMessage: 'Invalid response', status: 500, data: {}),
        );
      }
      return StoreSectionModel.fromJson(Map<String, dynamic>.from(sectionMap));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<void> deleteStoreSection({required String id}) async {
    try {
      await api.post(
        EndPoints.storeSectionsDelete,
        data: {'section_id': id},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<int> moveProductsLocation({
    required List<int> productIds,
    required String sectionId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.productsLocationMove,
        data: {
          'product_ids': productIds,
          'store_section_id': int.parse(sectionId),
        },
      );
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw is Map
                ? (raw['message']?.toString() ?? 'Unknown error')
                : 'Unknown error',
            status: 500,
            data: raw is Map ? Map<String, dynamic>.from(raw) : {},
          ),
        );
      }
      return raw['updated'] is int
          ? raw['updated'] as int
          : int.tryParse('${raw['updated']}') ?? productIds.length;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<int> adjustProductStock({
    required String productId,
    String? sizeColorId,
    required int quantity,
    String? note,
  }) async {
    try {
      final response = await api.post(
        EndPoints.productStockAdjust,
        data: {
          'product_id': productId,
          if (sizeColorId != null && sizeColorId.isNotEmpty)
            'size_color_id': sizeColorId,
          'quantity': quantity,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw is Map
                ? (raw['message']?.toString() ?? 'Unknown error')
                : 'Unknown error',
            status: 422,
            data: raw is Map ? Map<String, dynamic>.from(raw) : {},
          ),
        );
      }
      return asInt(raw['product_stock']);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<StockMovementsPageResult> getProductStockMovements({
    required String productId,
    int page = 1,
    int perPage = 50,
    String? dateFrom,
    String? dateTo,
    String? type,
  }) async {
    try {
      final response = await api.post(
        EndPoints.productStockMovements,
        data: {
          'product_id': productId,
          'page': page,
          'per_page': perPage,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw is Map
                ? (raw['message']?.toString() ?? 'Unknown error')
                : 'Unknown error',
            status: 500,
            data: raw is Map ? Map<String, dynamic>.from(raw) : {},
          ),
        );
      }
      return StockMovementsPageResult.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<int> swapProductsLocation({
    required List<int> groupA,
    required List<int> groupB,
    required SwapGroupLocationTarget groupATarget,
    required SwapGroupLocationTarget groupBTarget,
  }) async {
    try {
      final response = await api.post(
        EndPoints.productsLocationSwap,
        data: {
          'group_a': groupA,
          'group_b': groupB,
          'group_a_target': {
            'store_section_id': int.parse(groupATarget.sectionId),
          },
          'group_b_target': {
            'store_section_id': int.parse(groupBTarget.sectionId),
          },
        },
      );
      final raw = response.data;
      if (raw is! Map || raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw is Map
                ? (raw['message']?.toString() ?? 'Unknown error')
                : 'Unknown error',
            status: 500,
            data: raw is Map ? Map<String, dynamic>.from(raw) : {},
          ),
        );
      }
      return raw['swapped'] is int
          ? raw['swapped'] as int
          : int.tryParse('${raw['swapped']}') ?? groupA.length + groupB.length;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }
}
