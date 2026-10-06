import '../../../../../../core/databases/api/end_points.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStorePromotionsController extends OnlineStoreResourceController {
  OnlineStorePromotionsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStorePromotions);

  Future<Map<String, dynamic>> preview(Map<String, dynamic> payload) =>
      repository.post(EndPoints.onlineStorePricingPreview, data: payload);
}
