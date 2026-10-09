import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreNotificationBroadcastsController
    extends OnlineStoreResourceController {
  OnlineStoreNotificationBroadcastsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreNotificationBroadcasts);
}
