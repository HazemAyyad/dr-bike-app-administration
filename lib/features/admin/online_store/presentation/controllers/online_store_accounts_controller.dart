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
  final parties = <OnlineStoreParty>[].obs;
  final customerParties = <OnlineStoreParty>[].obs;
  final sellerParties = <OnlineStoreParty>[].obs;
  final partiesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final results = await Future.wait<dynamic>([
        repository.accounts(search: search.text),
        repository.parties('customer'),
        repository.parties('seller'),
      ]);
      accounts.assignAll(results[0] as List<OnlineStoreAccount>);
      customerParties.assignAll(results[1] as List<OnlineStoreParty>);
      sellerParties.assignAll(results[2] as List<OnlineStoreParty>);
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
      error.value = _message(e);
      Get.snackbar('تعذر ربط الحساب', error.value!,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<void> loadParties(String role) async {
    partiesLoading.value = true;
    error.value = null;
    try {
      final loaded = await repository.parties(role);
      parties.assignAll(loaded);
      (role == 'seller' ? sellerParties : customerParties).assignAll(loaded);
    } catch (e) {
      error.value = _message(e);
    } finally {
      partiesLoading.value = false;
    }
  }

  String partyName(OnlineStoreAccountLink link) {
    if (link.partyName?.trim().isNotEmpty == true) return link.partyName!;
    final source = link.role == 'seller' ? sellerParties : customerParties;
    for (final party in source) {
      if (party.id == link.partyId) return party.name;
    }
    return link.role == 'seller' ? 'مورد مرتبط' : 'عميل مرتبط';
  }

  Future<void> setLinkStatus(int linkId, String status) async {
    try {
      await repository.patch('online-store/account-links/$linkId',
          data: {'status': status});
      await load();
    } catch (e) {
      error.value = _message(e);
      Get.snackbar('تعذر تحديث الربط', error.value!,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _message(Object value) {
    final text = value.toString().replaceFirst('Exception: ', '');
    return text.isEmpty ? 'تعذر إكمال العملية.' : text;
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
