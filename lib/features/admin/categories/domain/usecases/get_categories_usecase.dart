import '../../data/models/category_model.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUsecase {
  final CategoryRepository categoryRepository;

  GetCategoriesUsecase({required this.categoryRepository});

  Future<List<CategoryModel>> call() => categoryRepository.getAllCategories();
}
