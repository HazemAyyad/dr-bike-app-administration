import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreBannersController extends OnlineStoreResourceController {
  OnlineStoreBannersController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreBanners);
}
