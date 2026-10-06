import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreHomeSectionsController extends OnlineStoreResourceController {
  OnlineStoreHomeSectionsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreHomeSections);

  Future<bool> replaceItems(int sectionId, List<Map<String, dynamic>> items) =>
      repository
          .put('$endpoint/$sectionId/items', data: {'items': items})
          .then((_) => true)
          .catchError((_) => false);

  Future<void> reorderSections(List<int> ids) =>
      repository.reorderHomeSections(ids);

  Future<List<OnlineStoreListing>> pickerListings() => repository.allListings();
}
