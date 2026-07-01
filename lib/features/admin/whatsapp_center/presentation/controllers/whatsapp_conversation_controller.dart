import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../data/whatsapp_api_service.dart';
import '../../data/whatsapp_models.dart';

class WhatsAppConversationController extends GetxController {
  final WhatsAppApiService api;
  WhatsAppConversationController(this.api);
  final conversation = Rxn<WhatsAppConversation>();
  final messages = <WhatsAppMessage>[].obs;
  final loading = false.obs;
  final sending = false.obs;
  final mediaLoading = false.obs;
  final Map<int, Uint8List> _mediaCache = {};
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

  Future<void> pickAndSendAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'mp3',
        'm4a',
        'ogg',
        'wav',
        'mp4'
      ],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    sending.value = true;
    try {
      await api.sendWhatsAppMedia(id, file!.path!, file.name);
      await load();
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      sending.value = false;
    }
  }

  Future<void> showMedia(WhatsAppMessage message) async {
    mediaLoading.value = true;
    try {
      final bytes = await getMediaBytes(message);
      if (message.type == 'image') {
        Get.dialog(
          Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.black,
            child: Stack(children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 5,
                  child:
                      Center(child: Image.memory(bytes, fit: BoxFit.contain)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  tooltip: 'إغلاق',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: Get.back,
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => saveImage(message),
                  icon: const Icon(Icons.download),
                  label: const Text('تنزيل الصورة'),
                ),
              ),
            ]),
          ),
        );
      } else {
        final directory = await getTemporaryDirectory();
        final extension = message.type == 'video'
            ? 'mp4'
            : message.type == 'audio'
                ? 'ogg'
                : 'pdf';
        final file =
            File('${directory.path}/whatsapp-${message.id}.$extension');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر فتح المرفق: $e');
    } finally {
      mediaLoading.value = false;
    }
  }

  Future<Uint8List> getMediaBytes(WhatsAppMessage message) async {
    final cached = _mediaCache[message.id];
    if (cached != null) return cached;
    final bytes = Uint8List.fromList(await api.getMedia(message.id));
    _mediaCache[message.id] = bytes;
    return bytes;
  }

  Future<void> saveImage(WhatsAppMessage message) async {
    try {
      final bytes = await getMediaBytes(message);
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'whatsapp_${message.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      Get.snackbar('تم', 'تم حفظ الصورة في معرض الصور',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ الصورة: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> addAsPerson(String type, String name) async {
    try {
      await api.linkPerson(id, type, name);
      await load();
      Get.snackbar(
          'تم', type == 'customer' ? 'تمت إضافة الزبون' : 'تمت إضافة التاجر');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString());
      return false;
    }
  }

  @override
  void onClose() {
    input.dispose();
    super.onClose();
  }
}
