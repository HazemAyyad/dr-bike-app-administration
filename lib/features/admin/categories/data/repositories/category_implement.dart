import 'package:doctorbike/core/connection/network_info.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/category_repository.dart';
import '../datasources/category_datasource.dart';
import '../models/category_model.dart';
import '../models/sub_category_model.dart';

class CategoryImplement implements CategoryRepository {
  final NetworkInfo networkInfo;
  final CategoryDatasource categoryDatasource;

  CategoryImplement({required this.networkInfo, required this.categoryDatasource});

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.getAllCategories();
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Map<String, dynamic>> saveCategory({
    int? categoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    int sortOrder = 0,
    XFile? image,
  }) async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.saveCategory(
        categoryId: categoryId,
        nameAr: nameAr,
        nameEng: nameEng,
        nameAbree: nameAbree,
        sortOrder: sortOrder,
        image: image,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Map<String, dynamic>> toggleCategoryStatus({required int categoryId}) async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.toggleCategoryStatus(categoryId: categoryId);
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<List<SubCategoryModel>> getSubCategoriesByCategory({required int categoryId}) async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.getSubCategoriesByCategory(categoryId: categoryId);
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Map<String, dynamic>> saveSubCategory({
    int? subCategoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    required int mainCategoryId,
    int sortOrder = 0,
    XFile? image,
  }) async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.saveSubCategory(
        subCategoryId: subCategoryId,
        nameAr: nameAr,
        nameEng: nameEng,
        nameAbree: nameAbree,
        mainCategoryId: mainCategoryId,
        sortOrder: sortOrder,
        image: image,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Map<String, dynamic>> toggleSubCategoryStatus({required int subCategoryId}) async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await categoryDatasource.toggleSubCategoryStatus(subCategoryId: subCategoryId);
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
