import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

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
  final scrollController = ScrollController();
  final composing = false.obs;
  final customerServiceWindowOpen = true.obs;
  final customerServiceWindowExpiresAt = Rxn<DateTime>();
  final replyingTo = Rxn<WhatsAppMessage>();
  late final RecorderController recorder;
  final recording = false.obs;
  final recordingPaused = false.obs;
  final recordingLocked = false.obs;
  final recordingDuration = Duration.zero.obs;
  Timer? _recordingTimer;
  Timer? _refreshTimer;
  Timer? _typingDebounce;
  DateTime? _lastTypingSentAt;
  String? _recordingPath;
  bool _openedAtLatestMessage = false;
  late int id;

  @override
  void onInit() {
    super.onInit();
    id = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    recorder = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    input.addListener(_onTextChanged);
    load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) async {
    final wasNearBottom = !scrollController.hasClients ||
        scrollController.position.maxScrollExtent -
                scrollController.position.pixels <
            140;
    if (!silent) loading.value = true;
    error.value = null;
    try {
      final result = await api.getWhatsAppConversationDetails(id);
      if (result['conversation'] is Map) {
        conversation.value = WhatsAppConversation.fromJson(
            Map<String, dynamic>.from(result['conversation'] as Map));
      }
      final block = result['messages'];
      final serviceWindow = result['customer_service_window'];
      if (serviceWindow is Map) {
        customerServiceWindowOpen.value = serviceWindow['open'] == true;
        customerServiceWindowExpiresAt.value =
            DateTime.tryParse(serviceWindow['expires_at']?.toString() ?? '');
      }
      final data = block is Map && block['data'] is List
          ? block['data'] as List
          : const [];
      messages.assignAll(data
          .whereType<Map>()
          .map((e) => WhatsAppMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          .reversed);
      if (serviceWindow is! Map) {
        final inboundDates = messages
            .where((message) =>
                message.direction == 'inbound' && message.createdAt != null)
            .map((message) => message.createdAt!)
            .toList();
        inboundDates.sort();
        final lastInbound =
            inboundDates.isEmpty ? null : inboundDates.last.toLocal();
        customerServiceWindowExpiresAt.value =
            lastInbound?.add(const Duration(hours: 24));
        customerServiceWindowOpen.value =
            customerServiceWindowExpiresAt.value?.isAfter(DateTime.now()) ==
                true;
      }
      if (!_openedAtLatestMessage || wasNearBottom) {
        _openedAtLatestMessage = true;
        _scrollToLatest();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      if (!silent) loading.value = false;
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  void _onTextChanged() {
    composing.value = input.text.trim().isNotEmpty;
    if (!composing.value) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 350), () async {
      final now = DateTime.now();
      if (_lastTypingSentAt != null &&
          now.difference(_lastTypingSentAt!) < const Duration(seconds: 4)) {
        return;
      }
      _lastTypingSentAt = now;
      try {
        await api.sendTypingIndicator(id);
      } catch (_) {
        // Typing is best-effort and must never interrupt composing a message.
      }
    });
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending.value) return;
    sending.value = true;
    try {
      await api.sendWhatsAppMessageToConversation(
        id,
        text,
        replyToMessageId: replyingTo.value?.id,
      );
      input.clear();
      replyingTo.value = null;
      await load();
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      sending.value = false;
    }
  }

  Future<void> requestContinuation() async {
    if (sending.value) return;
    sending.value = true;
    try {
      await api.requestConversationContinuation(id);
      await load(silent: true);
      Get.snackbar('تم الإرسال', 'تم إرسال طلب الاستمرار إلى الزبون');
    } catch (e) {
      Get.snackbar('تعذر إرسال القالب', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      sending.value = false;
    }
  }

  void replyTo(WhatsAppMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  Future<void> hideMessage(WhatsAppMessage message) async {
    try {
      await api.hideMessage(id, message.id);
      messages.removeWhere((item) => item.id == message.id);
      if (replyingTo.value?.id == message.id) replyingTo.value = null;
      Get.snackbar('تم', 'تم حذف الرسالة من عرضك فقط');
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> sendSelectedProducts(List<String> productIds) async {
    if (productIds.isEmpty || sending.value) return false;
    sending.value = true;
    try {
      await api.sendProducts(id, productIds);
      await load(silent: true);
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
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

  Future<void> pickAndSendVideo({required bool fromCamera}) async {
    final picked = await ImagePicker().pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (picked == null) return;
    await _sendMediaPath(picked.path, picked.name, mediaKind: 'video');
  }

  Future<void> pickAndSendImage({required bool fromCamera}) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return;
    await _sendMediaPath(picked.path, picked.name, mediaKind: 'image');
  }

  Future<void> sendCapturedMedia(String path, String mediaKind) async {
    final name = File(path).uri.pathSegments.last;
    await _sendMediaPath(path, name, mediaKind: mediaKind);
  }

  Future<void> startRecording() async {
    if (recording.value || sending.value) return;
    var permission = await Permission.microphone.status;
    if (!permission.isGranted) {
      permission = await Permission.microphone.request();
    }
    if (!permission.isGranted) {
      Get.snackbar(
          'صلاحية مطلوبة', 'يجب السماح باستخدام الميكروفون لتسجيل رسالة صوتية');
      return;
    }
    final directory = await getTemporaryDirectory();
    _recordingPath =
        '${directory.path}/whatsapp_voice_${DateTime.now().millisecondsSinceEpoch}.mp4';
    try {
      await recorder.record(path: _recordingPath!);
      recordingDuration.value = Duration.zero;
      recordingPaused.value = false;
      recordingLocked.value = false;
      recording.value = true;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!recordingPaused.value) {
            recordingDuration.value += const Duration(seconds: 1);
          }
        },
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر بدء التسجيل: $e');
    }
  }

  Future<void> cancelRecording() async {
    if (!recording.value) return;
    _recordingTimer?.cancel();
    try {
      final path = await recorder.stop() ?? _recordingPath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    recording.value = false;
    recordingPaused.value = false;
    recordingLocked.value = false;
    recordingDuration.value = Duration.zero;
    _recordingPath = null;
  }

  void lockRecording() {
    if (recording.value) recordingLocked.value = true;
  }

  Future<void> toggleRecordingPause() async {
    if (!recording.value) return;
    try {
      if (recordingPaused.value) {
        await recorder.record();
        recordingPaused.value = false;
      } else {
        await recorder.pause();
        recordingPaused.value = true;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر إيقاف أو متابعة التسجيل: $e');
    }
  }

  Future<void> stopAndSendRecording() async {
    if (!recording.value) return;
    _recordingTimer?.cancel();
    try {
      final path = await recorder.stop() ?? _recordingPath;
      recording.value = false;
      if (path == null || !await File(path).exists()) return;
      await _sendMediaPath(
        path,
        path.split(Platform.pathSeparator).last,
        mediaKind: 'audio',
      );
    } catch (e) {
      recording.value = false;
      Get.snackbar('خطأ', 'تعذر إرسال التسجيل: $e');
    } finally {
      recordingDuration.value = Duration.zero;
      recordingPaused.value = false;
      recordingLocked.value = false;
      _recordingPath = null;
    }
  }

  Future<void> _sendMediaPath(String path, String name,
      {String? mediaKind}) async {
    if (sending.value) return;
    sending.value = true;
    try {
      await api.sendWhatsAppMedia(id, path, name, mediaKind: mediaKind);
      await load(silent: true);
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
    _refreshTimer?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    input.removeListener(_onTextChanged);
    recorder.dispose();
    scrollController.dispose();
    input.dispose();
    super.onClose();
  }
}
