import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/banks_service.dart';

class BanksSettingsController extends GetxController {
  final nameController = TextEditingController();
  final RxnInt editingId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<BanksService>()) {
      Get.put(BanksService());
    }
    Get.find<BanksService>().loadBanks();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  void startEdit(BankItem bank) {
    editingId.value = bank.id;
    nameController.text = bank.name;
  }

  void clearForm() {
    editingId.value = null;
    nameController.clear();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('error'.tr, 'bankName'.tr);
      return;
    }
    final svc = Get.find<BanksService>();
    final ok = editingId.value != null
        ? await svc.updateBank(id: editingId.value!, name: name)
        : await svc.addBank(name: name);
    if (ok) {
      clearForm();
      Get.snackbar('success'.tr, 'save'.tr);
    }
  }

  Future<void> remove(int id) async {
    await Get.find<BanksService>().deleteBank(id);
  }
}
