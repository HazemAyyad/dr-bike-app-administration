import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/whatsapp_api_service.dart';
import '../../data/whatsapp_models.dart';

class WhatsAppConversationController extends GetxController {
  final WhatsAppApiService api;
  WhatsAppConversationController(this.api);
  final conversation = Rxn<WhatsAppConversation>();
  final messages = <WhatsAppMessage>[].obs;
  final loading = false.obs;
  final sending = false.obs;
  final error = RxnString();
  final input = TextEditingController();
  late int id;

  @override
  void onInit() {
    super.onInit();
    id = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final result = await api.getWhatsAppConversationDetails(id);
      if (result['conversation'] is Map) {
        conversation.value = WhatsAppConversation.fromJson(
            Map<String, dynamic>.from(result['conversation'] as Map));
      }
      final block = result['messages'];
      final data = block is Map && block['data'] is List
          ? block['data'] as List
          : const [];
      messages.assignAll(data
          .whereType<Map>()
          .map((e) => WhatsAppMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          .reversed);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending.value) return;
    sending.value = true;
    try {
      await api.sendWhatsAppMessageToConversation(id, text);
      input.clear();
      await load();
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      sending.value = false;
    }
  }

  @override
  void onClose() {
    input.dispose();
    super.onClose();
  }
}
