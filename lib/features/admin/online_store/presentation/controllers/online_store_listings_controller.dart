import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../utils/online_store_feedback.dart';

class OnlineStoreListingCategories {
  const OnlineStoreListingCategories(this.categories, this.selectedIds);
  final List<OnlineStoreEntity> categories;
  final Set<int> selectedIds;
}

class OnlineStoreListingsController extends GetxController {
  OnlineStoreListingsController(this.repository);
  final OnlineStoreRepository repository;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final status = 'all'.obs;
  final search = ''.obs;
  final items = <OnlineStoreListing>[].obs;

  List<OnlineStoreListing> get visibleItems {
    final term = search.value.trim().toLowerCase();
    final selectedStatus = status.value;
    return items
        .where(
            (item) => selectedStatus == 'all' || item.status == selectedStatus)
        .where((item) =>
            term.isEmpty ||
            item.productName.toLowerCase().contains(term) ||
            item.productCode.toLowerCase().contains(term) ||
            '${item.productId}'.contains(term))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      items.assignAll(await repository.allListings());
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<OnlineStoreListing?> create(int productId) async =>
      _save(() => repository.createListing(productId));

  Future<OnlineStoreListingCategories> listingCategories(int listingId) async {
    final categories =
        await repository.allEntities(EndPoints.onlineStoreCategories);
    final selected = <int>{};
    for (final category in categories) {
      final detail = await repository
          .get('${EndPoints.onlineStoreCategories}/${category.id}');
      final values = onlineStoreMap(detail['data']);
      final memberships = onlineStoreRows(values['memberships']);
      if (memberships.any((row) =>
          int.tryParse(
              '${row['online_store_listing_id'] ?? row['listing_id']}') ==
          listingId)) {
        selected.add(category.id);
      }
    }
    return OnlineStoreListingCategories(categories, selected);
  }

  Future<void> saveListingCategories(
      int listingId, Set<int> selectedCategoryIds) async {
    final snapshot = await listingCategories(listingId);
    for (final category in snapshot.categories) {
      final shouldContain = selectedCategoryIds.contains(category.id);
      final contains = snapshot.selectedIds.contains(category.id);
      if (shouldContain == contains) continue;
      final detail = await repository
          .get('${EndPoints.onlineStoreCategories}/${category.id}');
      final memberships =
          onlineStoreRows(onlineStoreMap(detail['data'])['memberships']);
      final listingIds = memberships
          .map((row) => int.tryParse(
              '${row['online_store_listing_id'] ?? row['listing_id']}'))
          .whereType<int>()
          .where((id) => id != listingId)
          .toList();
      if (shouldContain) listingIds.add(listingId);
      await repository.put(
        '${EndPoints.onlineStoreCategories}/${category.id}/listings',
        data: {
          'items': listingIds
              .asMap()
              .entries
              .map((entry) => {
                    'listing_id': entry.value,
                    'sort_order': entry.key,
                  })
              .toList(),
        },
      );
    }
  }

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
      error.value = OnlineStoreFeedback.message(e);
      OnlineStoreFeedback.error(e);
      return null;
    } finally {
      saving.value = false;
    }
  }
}
