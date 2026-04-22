import 'package:image_picker/image_picker.dart';

import '../../data/models/category_model.dart';
import '../../data/models/sub_category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getAllCategories();

  Future<Map<String, dynamic>> saveCategory({
    int? categoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    int sortOrder = 0,
    XFile? image,
  });

  Future<Map<String, dynamic>> toggleCategoryStatus({required int categoryId});

  Future<List<SubCategoryModel>> getSubCategoriesByCategory({required int categoryId});

  Future<Map<String, dynamic>> saveSubCategory({
    int? subCategoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    required int mainCategoryId,
    int sortOrder = 0,
    XFile? image,
  });

  Future<Map<String, dynamic>> toggleSubCategoryStatus({required int subCategoryId});
}
