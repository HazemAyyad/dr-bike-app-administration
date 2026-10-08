import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreCouponsController extends OnlineStoreResourceController {
  OnlineStoreCouponsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreCoupons);

  Future<OnlineStoreCouponHistory> redemptions(int couponId) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    var summary = <String, dynamic>{};
    do {
      final response = await repository.get(
        '$endpoint/$couponId/redemptions',
        query: {'page': page},
      );
      rows.addAll(onlineStoreRows(response['data']));
      if (page == 1) summary = onlineStoreMap(response['summary']);
      final meta = onlineStoreMap(response['meta']);
      lastPage = int.tryParse('${meta['last_page'] ?? 1}') ?? 1;
      page++;
    } while (page <= lastPage);
    return OnlineStoreCouponHistory(rows: rows, summary: summary);
  }
}

class OnlineStoreCouponHistory {
  const OnlineStoreCouponHistory({required this.rows, required this.summary});

  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
}
