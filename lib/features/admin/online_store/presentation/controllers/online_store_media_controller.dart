import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
      final payload = onlineStoreMap(json['data']);
      items.assignAll(onlineStoreRows(payload['items'])
          .map((row) => OnlineStoreMedia.fromJson(row)));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> addStoreImage(XFile file) async {
    saving.value = true;
    error.value = null;
    try {
      final path = await repository.uploadProductImage(file);
      final key = -DateTime.now().microsecondsSinceEpoch;
      items.add(OnlineStoreMedia(
        sourceMediaId: key,
        sourceType: 'store_specific',
        storeMediaPath: path,
        url: path,
        sortOrder: items.length,
        isMain: items.isEmpty,
      ));
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('تعذر رفع الصورة', error.value!,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      saving.value = false;
    }
  }

  Future<void> addStoreVideo(XFile file) async {
    saving.value = true;
    error.value = null;
    try {
      final uploaded = await repository.uploadProductMedia(file);
      final path = '${uploaded['path'] ?? ''}';
      final key = -DateTime.now().microsecondsSinceEpoch;
      items.add(OnlineStoreMedia(
        sourceMediaId: key,
        sourceType: 'store_specific',
        storeMediaPath: path,
        url: path,
        sortOrder: items.length,
        isMain: items.isEmpty,
        mediaMetadata: {
          'media_type': 'video',
          'mime_type': '${uploaded['mime_type'] ?? 'video/mp4'}',
          'role': 'video',
        },
      ));
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('تعذر رفع الفيديو', error.value!,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      saving.value = false;
    }
  }

  void setRole(int mediaKey, String role) {
    items.assignAll(items.map((item) {
      if (item.sourceMediaId != mediaKey) return item;
      return item.copyWith(mediaMetadata: {
        ...item.mediaMetadata,
        'role': role,
        if (role == 'video') 'media_type': 'video',
      });
    }).toList());
  }

  void remove(int mediaKey) {
    final wasMain =
        items.any((item) => item.sourceMediaId == mediaKey && item.isMain);
    items.removeWhere((item) => item.sourceMediaId == mediaKey);
    if (wasMain && items.isNotEmpty) {
      selectMain(items.first.sourceMediaId);
    }
    items.assignAll(items
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(sortOrder: entry.key)));
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
        'items': items.map((item) => item.toRequestJson()).toList(),
      });
      await load(listingId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      saving.value = false;
    }
  }
}
