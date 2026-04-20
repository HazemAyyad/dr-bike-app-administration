import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/errors/error_model.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../models/sub_category_model.dart';

class CategoryDatasource {
  final ApiConsumer api;

  CategoryDatasource({required this.api});

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await api.get(EndPoints.getAllCategoriesManagement);
      final list = (response.data['categories'] as List)
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }

  Future<Map<String, dynamic>> saveCategory({
    int? categoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    XFile? image,
  }) async {
    try {
      final endpoint = categoryId != null
          ? EndPoints.updateCategoryAdmin
          : EndPoints.storeCategoryAdmin;
      final Map<String, dynamic> data = {
        if (categoryId != null) 'category_id': categoryId,
        'nameAr': nameAr,
        if (nameEng.isNotEmpty) 'nameEng': nameEng,
        if (nameAbree.isNotEmpty) 'nameAbree': nameAbree,
      };
      if (image != null) {
        final bytes = await image.readAsBytes();
        data['image'] = MultipartFile.fromBytes(bytes, filename: image.name);
      }
      final response = await api.post(endpoint, data: data, isFormData: true);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }

  Future<Map<String, dynamic>> toggleCategoryStatus({required int categoryId}) async {
    try {
      final response = await api.post(EndPoints.toggleCategoryStatusAdmin,
          data: {'category_id': categoryId});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }

  Future<List<SubCategoryModel>> getSubCategoriesByCategory({required int categoryId}) async {
    try {
      final response = await api.post(EndPoints.getSubCategoriesByCategory,
          data: {'category_id': categoryId});
      final list = (response.data['sub_categories'] as List)
          .map((e) => SubCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }

  Future<Map<String, dynamic>> saveSubCategory({
    int? subCategoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    required int mainCategoryId,
    XFile? image,
  }) async {
    try {
      final endpoint = subCategoryId != null
          ? EndPoints.updateSubCategoryAdmin
          : EndPoints.storeSubCategoryAdmin;
      final Map<String, dynamic> body = {
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        'nameAr': nameAr,
        if (nameEng.isNotEmpty) 'nameEng': nameEng,
        if (nameAbree.isNotEmpty) 'nameAbree': nameAbree,
        'mainCategoryId': mainCategoryId,
      };
      if (image != null) {
        final bytes = await image.readAsBytes();
        body['image'] = MultipartFile.fromBytes(bytes, filename: image.name);
      }
      final response = await api.post(endpoint, data: body, isFormData: true);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }

  Future<Map<String, dynamic>> toggleSubCategoryStatus({required int subCategoryId}) async {
    try {
      final response = await api.post(EndPoints.toggleSubCategoryStatusAdmin,
          data: {'sub_category_id': subCategoryId});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(ErrorModel(
        errorMessage: data?['message'] ?? 'Unknown error',
        status: data?['status'] ?? 500,
        data: data ?? {},
      ));
    }
  }
}
