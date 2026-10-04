import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreMediaController extends GetxController {
  OnlineStoreMediaController(this.repository);
  final OnlineStoreRepository repository;
  final items = <OnlineStoreMedia>[].obs;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  int listingId = 0;

  Future<void> load(int id) async {
    listingId = id;
    loading.value = true;
    try {
      final json = await repository.get('online-store/listings/$id/media');
      items.assignAll(onlineStoreRows(json['data'])
          .map((row) => OnlineStoreMedia.fromJson(row)));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void selectMain(int sourceId) {
    items.assignAll(items
        .map((item) => item.copyWith(
              isMain: item.sourceMediaId == sourceId,
              isVisible: item.sourceMediaId == sourceId ? true : item.isVisible,
            ))
        .toList());
  }

  void toggleVisible(int sourceId) {
    items.assignAll(items
        .map((item) => item.sourceMediaId == sourceId
            ? item.copyWith(isVisible: item.isMain ? true : !item.isVisible)
            : item)
        .toList());
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final next = items.toList();
    next.insert(newIndex, next.removeAt(oldIndex));
    items.assignAll(next
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(sortOrder: entry.key)));
  }

  Future<void> save() async {
    saving.value = true;
    try {
      await repository.put('online-store/listings/$listingId/media', data: {
        'media': items.map((item) => item.toRequestJson()).toList(),
      });
      await load(listingId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      saving.value = false;
    }
  }
}
