import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreAccountsController extends GetxController {
  OnlineStoreAccountsController(this.repository);
  final OnlineStoreRepository repository;
  final search = TextEditingController();
  final loading = false.obs;
  final error = RxnString();
  final accounts = <OnlineStoreAccount>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      accounts.assignAll(await repository.accounts(search: search.text));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<bool> link({
    required int userId,
    required String role,
    required int partyId,
  }) async {
    try {
      await repository.post('online-store/account-links', data: {
        'user_id': userId,
        'role': role,
        if (role == 'customer') 'customer_id': partyId,
        if (role == 'seller') 'seller_id': partyId,
        'account_source': 'admin_app',
        'status': 'active',
      });
      await load();
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  Future<void> setLinkStatus(int linkId, String status) async {
    await repository
        .patch('online-store/account-links/$linkId', data: {'status': status});
    await load();
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
