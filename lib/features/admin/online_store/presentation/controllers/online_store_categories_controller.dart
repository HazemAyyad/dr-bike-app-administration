import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

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
}
