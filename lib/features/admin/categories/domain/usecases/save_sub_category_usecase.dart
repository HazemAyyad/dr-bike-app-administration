import 'package:image_picker/image_picker.dart';

import '../../data/models/sub_category_model.dart';
import '../repositories/category_repository.dart';

class GetSubCategoriesUsecase {
  final CategoryRepository categoryRepository;

  GetSubCategoriesUsecase({required this.categoryRepository});

  Future<List<SubCategoryModel>> call({required int categoryId}) =>
      categoryRepository.getSubCategoriesByCategory(categoryId: categoryId);
}

class SaveSubCategoryUsecase {
  final CategoryRepository categoryRepository;

  SaveSubCategoryUsecase({required this.categoryRepository});

  Future<Map<String, dynamic>> call({
    int? subCategoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    required int mainCategoryId,
    XFile? image,
  }) =>
      categoryRepository.saveSubCategory(
        subCategoryId: subCategoryId,
        nameAr: nameAr,
        nameEng: nameEng,
        nameAbree: nameAbree,
        mainCategoryId: mainCategoryId,
        image: image,
      );
}

class ToggleSubCategoryStatusUsecase {
  final CategoryRepository categoryRepository;

  ToggleSubCategoryStatusUsecase({required this.categoryRepository});

  Future<Map<String, dynamic>> call({required int subCategoryId}) =>
      categoryRepository.toggleSubCategoryStatus(subCategoryId: subCategoryId);
}
