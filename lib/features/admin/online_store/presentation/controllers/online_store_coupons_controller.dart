import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreCouponsController extends OnlineStoreResourceController {
  OnlineStoreCouponsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreCoupons);

  Future<List<Map<String, dynamic>>> redemptions(int couponId) async =>
      onlineStoreRows(
          (await repository.get('$endpoint/$couponId/redemptions'))['data']);
}
