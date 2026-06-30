import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/whatsapp_api_service.dart';
import '../../data/whatsapp_models.dart';

class WhatsAppCenterController extends GetxController {
  final WhatsAppApiService api;
  WhatsAppCenterController(this.api);

  final tabIndex = 0.obs;
  final loading = false.obs;
  final actionLoading = false.obs;
  final error = RxnString();
  final dashboard = Rxn<WhatsAppDashboard>();
  final conversations = <WhatsAppConversation>[].obs;
  final templates = <WhatsAppTemplate>[].obs;
  final settings = Rxn<WhatsAppSettings>();
  final selectedStatus = 'all'.obs;
  final searchController = TextEditingController();
  final testPhoneController = TextEditingController();
  final testMessageController =
      TextEditingController(text: 'رسالة تجربة من دكتور بايك');

  @override
  void onInit() {
    super.onInit();
    refreshCurrent();
  }

  Future<void> selectTab(int index) async {
    tabIndex.value = index;
    await refreshCurrent();
  }

  Future<void> refreshCurrent() async {
    switch (tabIndex.value) {
      case 1:
        await loadConversations();
        break;
      case 2:
        await loadTemplates();
        break;
      case 3:
        await loadSettings();
        break;
      default:
        await loadDashboard();
    }
  }

  Future<void> _load(Future<void> Function() task) async {
    loading.value = true;
    error.value = null;
    try {
      await task();
    } catch (e) {
      error.value = _message(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadDashboard() => _load(() async {
        final result = await api.getWhatsAppDashboard();
        dashboard.value = WhatsAppDashboard.fromJson(
            Map<String, dynamic>.from(result['dashboard'] as Map? ?? {}));
      });

  Future<void> loadConversations() => _load(() async {
        final result = await api.getWhatsAppConversations(
            search: searchController.text, status: selectedStatus.value);
        final block = result['conversations'];
        final data = block is Map && block['data'] is List
            ? block['data'] as List
            : const [];
        conversations.assignAll(data.whereType<Map>().map((e) =>
            WhatsAppConversation.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadTemplates() => _load(() async {
        final result = await api.getWhatsAppTemplates();
        final data = result['templates'] is List
            ? result['templates'] as List
            : const [];
        templates.assignAll(data.whereType<Map>().map(
            (e) => WhatsAppTemplate.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadSettings() => _load(() async {
        settings.value =
            WhatsAppSettings.fromJson(await api.getWhatsAppSettings());
      });

  Future<bool> sendDirect(String phone, String message,
      {bool test = false}) async {
    if (phone.trim().isEmpty || message.trim().isEmpty) return false;
    actionLoading.value = true;
    try {
      final result = test
          ? await api.sendWhatsAppTestMessage(phone.trim(), message.trim())
          : await api.sendWhatsAppText(phone.trim(), message.trim());
      if (result['status'] != 'success') {
        throw Exception(result['message'] ?? 'تعذر الإرسال');
      }
      Get.snackbar('تم', 'تم إرسال الرسالة بنجاح');
      await loadDashboard();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<bool> saveTemplate(Map<String, dynamic> data, {int? id}) async {
    actionLoading.value = true;
    try {
      if (id == null) {
        await api.createWhatsAppTemplate(data);
      } else {
        await api.updateWhatsAppTemplate(id, data);
      }
      await loadTemplates();
      Get.snackbar('تم', 'تم حفظ القالب');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> deleteTemplate(int id) async {
    actionLoading.value = true;
    try {
      await api.deleteWhatsAppTemplate(id);
      templates.removeWhere((item) => item.id == id);
      Get.snackbar('تم', 'تم حذف القالب');
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionLoading.value = false;
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void onClose() {
    searchController.dispose();
    testPhoneController.dispose();
    testMessageController.dispose();
    super.onClose();
  }
}
