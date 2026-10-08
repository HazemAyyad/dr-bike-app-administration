import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class OnlineStoreCategoriesController extends OnlineStoreResourceController {
  OnlineStoreCategoriesController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreCategories);

  Future<bool> replaceListings(int categoryId, List<int> listingIds) =>
      repository
          .put('$endpoint/$categoryId/listings', data: {
            'items': listingIds
                .asMap()
                .entries
                .map((entry) => {
                      'listing_id': entry.value,
                      'sort_order': entry.key,
                    })
                .toList(),
          })
          .then((_) => true)
          .catchError((_) => false);

  Future<void> reorderCategories(List<int> ids) =>
      repository.reorderCategories(ids);

  Future<List<OnlineStoreListing>> pickerListings() => repository.allListings();

  Future<String> uploadImage(XFile file) => repository.uploadContentImage(file);

  @override
  Future<bool> remove(int id) async {
    return removeWithReplacement(id, null);
  }

  Future<bool> removeWithReplacement(int id, int? replacementCategoryId) async {
    saving.value = true;
    error.value = null;
    try {
      final response = await repository.delete('$endpoint/$id', data: {
        if (replacementCategoryId != null)
          'replacement_category_id': replacementCategoryId,
      });
      final disposition = '${onlineStoreMap(response['data'])['disposition']}';
      await load();
      if (disposition == 'deleted') {
        Get.snackbar('تم حذف التصنيف', 'حُذف التصنيف غير المستخدم نهائياً.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar(
          'تمت أرشفة التصنيف',
          'التصنيف مرتبط ببيانات المتجر، لذلك أُوقف وأُخفي مع الاحتفاظ بالسجل.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return true;
    } catch (exception) {
      final message = exception.toString().replaceFirst('Exception: ', '');
      error.value = message.contains('Move or remove child categories first')
          ? 'انقل التصنيفات الفرعية أو احذفها أولاً.'
          : message.contains('Choose a destination category')
              ? 'اختر التصنيف الذي ستنتقل إليه المنتجات أولاً.'
              : message.contains('destination category must be active')
                  ? 'يجب أن يكون التصنيف البديل نشطًا.'
                  : message;
      Get.snackbar('تعذر حذف التصنيف', error.value!,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      saving.value = false;
    }
  }
}
