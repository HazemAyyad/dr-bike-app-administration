import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreListingsController extends GetxController {
  OnlineStoreListingsController(this.repository);
  final OnlineStoreRepository repository;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final status = 'all'.obs;
  final items = <OnlineStoreListing>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      items.assignAll((await repository.listings(status: status.value)).items);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<OnlineStoreListing?> create(int productId) async =>
      _save(() => repository.createListing(productId));

  Future<OnlineStoreListing?> updateListing(
    OnlineStoreListing listing,
    Map<String, dynamic> payload,
  ) =>
      _save(() => repository.updateListing(listing.id, payload));

  Future<OnlineStoreListing?> transition(
    OnlineStoreListing listing,
    String nextStatus,
  ) =>
      _save(() => repository.transitionListing(
            listing.id,
            nextStatus,
            updatedAt: listing.updatedAt,
          ));

  Future<OnlineStoreListing?> _save(
      Future<OnlineStoreListing> Function() operation) async {
    saving.value = true;
    try {
      final result = await operation();
      final index = items.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        items.insert(0, result);
      } else {
        items[index] = result;
      }
      return result;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('تعذر تنفيذ العملية', error.value!,
          snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      saving.value = false;
    }
  }
}
