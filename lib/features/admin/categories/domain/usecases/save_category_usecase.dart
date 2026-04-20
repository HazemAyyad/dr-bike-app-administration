import 'package:image_picker/image_picker.dart';

import '../repositories/category_repository.dart';

class SaveCategoryUsecase {
  final CategoryRepository categoryRepository;

  SaveCategoryUsecase({required this.categoryRepository});

  Future<Map<String, dynamic>> call({
    int? categoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    XFile? image,
  }) =>
      categoryRepository.saveCategory(
        categoryId: categoryId,
        nameAr: nameAr,
        nameEng: nameEng,
        nameAbree: nameAbree,
        image: image,
      );
}

class ToggleCategoryStatusUsecase {
  final CategoryRepository categoryRepository;

  ToggleCategoryStatusUsecase({required this.categoryRepository});

  Future<Map<String, dynamic>> call({required int categoryId}) =>
      categoryRepository.toggleCategoryStatus(categoryId: categoryId);
}
