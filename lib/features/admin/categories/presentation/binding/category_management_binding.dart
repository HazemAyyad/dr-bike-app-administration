import 'package:get/get.dart';

import '../../data/repositories/category_implement.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/save_category_usecase.dart';
import '../../domain/usecases/save_sub_category_usecase.dart';
import '../controllers/category_management_controller.dart';

class CategoryManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CategoryManagementController(
        getCategoriesUsecase: GetCategoriesUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
        saveCategoryUsecase: SaveCategoryUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
        toggleCategoryStatusUsecase: ToggleCategoryStatusUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
        getSubCategoriesUsecase: GetSubCategoriesUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
        saveSubCategoryUsecase: SaveSubCategoryUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
        toggleSubCategoryStatusUsecase: ToggleSubCategoryStatusUsecase(
          categoryRepository: Get.find<CategoryImplement>(),
        ),
      ),
    );
  }
}
