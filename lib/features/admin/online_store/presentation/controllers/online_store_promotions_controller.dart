import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStorePromotionsController extends OnlineStoreResourceController {
  OnlineStorePromotionsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStorePromotions);

  Future<Map<String, dynamic>> preview(Map<String, dynamic> payload) =>
      repository.post(EndPoints.onlineStorePricingPreview, data: payload);

  Future<OnlineStorePromotionHistory> redemptions(int promotionId) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    var summary = <String, dynamic>{};
    do {
      final response = await repository.get(
        '$endpoint/$promotionId/redemptions',
        query: {'page': page},
      );
      rows.addAll(onlineStoreRows(response['data']));
      if (page == 1) summary = onlineStoreMap(response['summary']);
      final meta = onlineStoreMap(response['meta']);
      lastPage = int.tryParse('${meta['last_page'] ?? 1}') ?? 1;
      page++;
    } while (page <= lastPage);
    return OnlineStorePromotionHistory(rows: rows, summary: summary);
  }
}

class OnlineStorePromotionHistory {
  const OnlineStorePromotionHistory(
      {required this.rows, required this.summary});

  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
}
