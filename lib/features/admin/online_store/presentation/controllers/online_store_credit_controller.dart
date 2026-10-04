import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreCreditController extends GetxController {
  OnlineStoreCreditController(this.repository);
  final OnlineStoreRepository repository;
  final snapshot = Rxn<OnlineStoreCreditSnapshot>();
  final loading = false.obs;
  final error = RxnString();
  int linkId = 0;

  Future<void> load(int id) async {
    linkId = id;
    loading.value = true;
    try {
      final json =
          await repository.get('online-store/account-links/$id/credit');
      snapshot.value = OnlineStoreCreditSnapshot.fromJson(
          onlineStoreMap(json['data']).isEmpty
              ? json
              : onlineStoreMap(json['data']));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> savePolicy({
    required bool eligible,
    double? limit,
    required String currency,
    String? expiresAt,
  }) async {
    await repository
        .put('online-store/account-links/$linkId/credit-policy', data: {
      'is_eligible': eligible,
      'credit_limit': limit,
      'currency': currency,
      'expires_at': expiresAt,
    });
    await load(linkId);
  }
}
