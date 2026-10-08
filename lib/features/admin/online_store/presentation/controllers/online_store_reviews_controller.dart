import '../../../../../../core/databases/api/end_points.dart';
import 'package:get/get.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import 'online_store_resource_controller.dart';

class OnlineStoreReviewsController extends OnlineStoreResourceController {
  OnlineStoreReviewsController(OnlineStoreRepository repository)
      : super(repository, EndPoints.onlineStoreReviews);

  final selectedStatus = 'all'.obs;

  @override
  Future<void> load({Map<String, dynamic>? query}) => super.load(query: {
        if (selectedStatus.value != 'all') 'status': selectedStatus.value,
      });

  void changeStatus(String status) {
    selectedStatus.value = status;
    load();
  }

  Future<bool> moderate(int id, String status, {String? reason}) => action(
        id,
        'moderate',
        payload: {
          'status': status,
          if (reason?.isNotEmpty == true) 'reason': reason
        },
      );

  bool verifiedPurchase(OnlineStoreEntity review) =>
      review.values['is_verified_purchase'] == true ||
      review.values['is_verified_purchase'] == 1;
}
