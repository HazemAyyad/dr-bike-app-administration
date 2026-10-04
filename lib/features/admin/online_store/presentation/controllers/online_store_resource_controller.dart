import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreResourceController extends GetxController {
  OnlineStoreResourceController(this.repository, this.endpoint);

  final OnlineStoreRepository repository;
  final String endpoint;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final items = <OnlineStoreEntity>[].obs;
  final search = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({Map<String, dynamic>? query}) async {
    loading.value = true;
    error.value = null;
    try {
      final response = await repository.get(endpoint, query: query);
      items.assignAll(
        onlineStoreRows(response['data'])
            .map((json) => OnlineStoreEntity.fromJson(json)),
      );
    } catch (e) {
      error.value = _message(e);
    } finally {
      loading.value = false;
    }
  }

  Future<bool> create(Map<String, dynamic> payload) => _mutate(
        () => repository.post(endpoint, data: payload),
      );

  Future<bool> updateItem(int id, Map<String, dynamic> payload) => _mutate(
        () => repository.patch('$endpoint/$id', data: payload),
      );

  Future<bool> remove(int id) => _mutate(
        () => repository.delete('$endpoint/$id'),
      );

  Future<bool> action(int id, String action, {Map<String, dynamic>? payload}) =>
      _mutate(
        () => repository.post('$endpoint/$id/$action', data: payload),
      );

  Future<bool> reorder(List<int> ids, {String? updatedAt}) => _mutate(
        () => repository.post('$endpoint/reorder', data: {
          'ids': ids,
          if (updatedAt != null) 'updated_at': updatedAt,
        }),
      );

  Future<bool> _mutate(
      Future<Map<String, dynamic>> Function() operation) async {
    saving.value = true;
    error.value = null;
    try {
      await operation();
      await load();
      return true;
    } catch (e) {
      error.value = _message(e);
      Get.snackbar('تعذر الحفظ', error.value!,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      saving.value = false;
    }
  }

  String _message(Object value) =>
      value.toString().replaceFirst('Exception: ', '');

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
