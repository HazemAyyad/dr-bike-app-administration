import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreReportsController extends GetxController {
  OnlineStoreReportsController(this.repository);
  final OnlineStoreRepository repository;
  final data = <String, dynamic>{}.obs;
  final loading = false.obs;
  final error = RxnString();
  final from = RxnString();
  final to = RxnString();
  final accountType = 'all'.obs;
  final origin = 'all'.obs;
  final status = 'all'.obs;
  final fromController = TextEditingController();
  final toController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fromController.addListener(() {
      from.value = fromController.text.trim().isEmpty
          ? null
          : fromController.text.trim();
    });
    toController.addListener(() {
      to.value =
          toController.text.trim().isEmpty ? null : toController.text.trim();
    });
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final json = await repository.get(EndPoints.onlineStoreReports, query: {
        if (from.value != null) 'from': from.value,
        if (to.value != null) 'to': to.value,
        if (accountType.value != 'all') 'account_type': accountType.value,
        if (origin.value != 'all') 'origin': origin.value,
        if (status.value != 'all') 'status': status.value,
      });
      data.assignAll(onlineStoreMap(json['data']).isEmpty
          ? json
          : onlineStoreMap(json['data']));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    super.onClose();
  }
}
