// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart' as svg;

import '../../data/whatsapp_api_service.dart';
import '../../data/whatsapp_models.dart';
import '../../../../../core/services/initial_bindings.dart';

class WhatsAppCenterController extends GetxController {
  final WhatsAppApiService api;
  WhatsAppCenterController(this.api);

  final tabIndex = 1.obs;
  final loading = false.obs;
  final actionLoading = false.obs;
  final error = RxnString();
  final dashboard = Rxn<WhatsAppDashboard>();
  final conversations = <WhatsAppConversation>[].obs;
  final conversationsScrollController = ScrollController();
  final loadingMoreConversations = false.obs;
  final hasMoreConversations = false.obs;
  Timer? _conversationsRefreshTimer;
  bool _refreshingConversations = false;
  int _conversationPage = 1;
  final Map<int, Future<Uint8List?>> _conversationThumbnails = {};
  final Map<int, Future<Duration?>> _conversationAudioDurations = {};
  final templates = <WhatsAppTemplate>[].obs;
  final settings = Rxn<WhatsAppSettings>();
  final whatsAppEmployees = <WhatsAppEmployeeAccess>[].obs;
  final selectedEmployeeChannelAccess = <int, Set<String>>{}.obs;
  final selectedWhatsAppAccountId = RxnInt();
  final canManageWhatsAppEmployees = false.obs;
  final qrBytes = Rxn<Uint8List>();
  final selectedStatus = 'all'.obs;
  final selectedQuickFilter = 'all'.obs;
  final selectedChannel = (userType == 'admin'
          ? 'all'
          : employeePermissionNames.contains('Social Center WhatsApp')
              ? 'whatsapp'
              : 'all')
      .obs;
  final searchController = TextEditingController();
  final testPhoneController = TextEditingController();
  final testMessageController =
      TextEditingController(text: 'رسالة تجربة من دكتور بايك');

  @override
  void onInit() {
    super.onInit();
    conversationsScrollController.addListener(_onConversationsScroll);
    refreshCurrent();
    _conversationsRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshConversationsSilently(),
    );
  }

  Future<void> selectTab(int index) async {
    tabIndex.value = index;
    await refreshCurrent();
  }

  Future<void> toggleSettings() => selectTab(tabIndex.value == 3 ? 1 : 3);

  Future<void> toggleDashboard() => selectTab(tabIndex.value == 0 ? 1 : 0);

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

  Future<void> loadConversations({bool append = false}) async {
    if (append) {
      if (loadingMoreConversations.value || !hasMoreConversations.value) return;
      loadingMoreConversations.value = true;
    } else {
      loading.value = true;
      error.value = null;
      _conversationPage = 1;
      hasMoreConversations.value = false;
      _conversationThumbnails.clear();
      _conversationAudioDurations.clear();
    }

    try {
      final page = append ? _conversationPage + 1 : 1;
      final result = await api.getWhatsAppConversations(
        search: searchController.text,
        status: selectedStatus.value,
        channel: selectedChannel.value,
        quickFilter: selectedQuickFilter.value,
        page: page,
        perPage: 20,
      );
      final block = result['conversations'];
      final data = block is Map && block['data'] is List
          ? block['data'] as List
          : const [];
      final items = data
          .whereType<Map>()
          .map((item) =>
              WhatsAppConversation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      append ? conversations.addAll(items) : conversations.assignAll(items);
      _conversationPage = int.tryParse(
              block is Map ? block['current_page']?.toString() ?? '1' : '1') ??
          page;
      final lastPage = int.tryParse(
              block is Map ? block['last_page']?.toString() ?? '' : '') ??
          _conversationPage;
      hasMoreConversations.value =
          selectedChannel.value == 'whatsapp' && _conversationPage < lastPage;
    } catch (e) {
      if (append) {
        Get.snackbar('تعذر تحميل المزيد', _message(e),
            snackPosition: SnackPosition.BOTTOM);
      } else {
        error.value = _message(e);
      }
    } finally {
      append ? loadingMoreConversations.value = false : loading.value = false;
    }
  }

  Future<void> _refreshConversationsSilently() async {
    if (tabIndex.value != 1 ||
        loading.value ||
        loadingMoreConversations.value ||
        _refreshingConversations) {
      return;
    }

    _refreshingConversations = true;
    try {
      final result = await api.getWhatsAppConversations(
        search: searchController.text,
        status: selectedStatus.value,
        channel: selectedChannel.value,
        quickFilter: selectedQuickFilter.value,
        page: 1,
        perPage: 20,
      );
      final block = result['conversations'];
      final data = block is Map && block['data'] is List
          ? block['data'] as List
          : const [];
      final items = data
          .whereType<Map>()
          .map((item) =>
              WhatsAppConversation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      conversations.assignAll(items);
      _conversationPage = 1;
      final lastPage = int.tryParse(
              block is Map ? block['last_page']?.toString() ?? '' : '') ??
          1;
      hasMoreConversations.value =
          selectedChannel.value == 'whatsapp' && lastPage > 1;
      _conversationThumbnails.clear();
      _conversationAudioDurations.clear();
    } catch (_) {
      // Periodic refresh stays silent; manual refresh still reports errors.
    } finally {
      _refreshingConversations = false;
    }
  }

  void _onConversationsScroll() {
    if (!conversationsScrollController.hasClients ||
        conversationsScrollController.position.extentAfter > 320) {
      return;
    }
    loadConversations(append: true);
  }

  Future<Uint8List?> conversationThumbnail(WhatsAppConversation item) {
    final messageId = item.lastMessageId;
    if (messageId == null) return Future<Uint8List?>.value();
    return _conversationThumbnails.putIfAbsent(messageId, () async {
      try {
        final bytes = Uint8List.fromList(await api.getMedia(messageId));
        if (item.lastMessageType == 'image') return bytes;
        if (item.lastMessageType != 'video') return null;
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/whatsapp-list-$messageId.mp4');
        await file.writeAsBytes(bytes, flush: true);
        return VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 180,
          quality: 68,
        );
      } catch (_) {
        return null;
      }
    });
  }

  Future<Duration?> conversationAudioDuration(WhatsAppConversation item) {
    final messageId = item.lastMessageId;
    if (messageId == null) return Future<Duration?>.value();
    final knownSeconds = item.lastMessageMedia?.durationSeconds;
    if (knownSeconds != null && knownSeconds > 0) {
      return Future<Duration?>.value(Duration(seconds: knownSeconds));
    }
    return _conversationAudioDurations.putIfAbsent(messageId, () async {
      final player = AudioPlayer();
      try {
        final bytes = await api.getMedia(messageId);
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/whatsapp-list-$messageId.m4a');
        await file.writeAsBytes(bytes, flush: true);
        return await player.setFilePath(file.path);
      } catch (_) {
        return null;
      } finally {
        await player.dispose();
      }
    });
  }

  Future<void> selectStatus(String status) async {
    selectedStatus.value = status;
    await loadConversations();
  }

  Future<void> selectQuickFilter(String filter) async {
    selectedQuickFilter.value = filter;
    await loadConversations();
  }

  Future<void> clearConversationFilters() async {
    selectedStatus.value = 'all';
    selectedQuickFilter.value = 'all';
    searchController.clear();
    await loadConversations();
  }

  Future<void> selectChannel(String channel) async {
    selectedChannel.value = channel;
    if (tabIndex.value == 3) {
      return;
    }
    tabIndex.value = 1;
    await loadConversations();
  }

  Future<void> loadTemplates() => _load(() async {
        final result = await api.getWhatsAppTemplates();
        final data = result['templates'] is List
            ? result['templates'] as List
            : const [];
        templates.assignAll(data.whereType<Map>().map(
            (e) => WhatsAppTemplate.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadSettings() => _load(() async {
        final result = await api.getWhatsAppSettings();
        settings.value = WhatsAppSettings.fromJson(result);
        selectedWhatsAppAccountId.value ??= _firstConfiguredWhatsAppAccountId();
        canManageWhatsAppEmployees.value =
            result['can_manage_employees'] == true;
        final employees = result['employees'] is List
            ? result['employees'] as List
            : const [];
        whatsAppEmployees.assignAll(employees.whereType<Map>().map((item) =>
            WhatsAppEmployeeAccess.fromJson(Map<String, dynamic>.from(item))));
        _syncEmployeeChannelAccess();
        try {
          qrBytes.value = Uint8List.fromList(
              await api.getQr(accountId: selectedWhatsAppAccountId.value));
        } catch (_) {
          qrBytes.value = null;
        }
      });

  List<SocialChannelSetting> get whatsAppAccountChannels =>
      settings.value?.channels
          .where((channel) =>
              channel.id == 'whatsapp' || channel.id.startsWith('whatsapp:'))
          .toList() ??
      const [];

  Future<void> selectWhatsAppAccount(int? accountId) async {
    selectedWhatsAppAccountId.value = accountId;
    try {
      qrBytes.value = Uint8List.fromList(await api.getQr(accountId: accountId));
    } catch (_) {
      qrBytes.value = null;
    }
  }

  void toggleSocialCenterEmployee(int id, bool selected) {
    final values = Map<int, Set<String>>.from(selectedEmployeeChannelAccess);
    selected ? values[id] = {'main'} : values.remove(id);
    selectedEmployeeChannelAccess.assignAll(values);
  }

  void toggleEmployeeChannel(int id, String channel, bool selected) {
    final values = Map<int, Set<String>>.from(selectedEmployeeChannelAccess);
    final channels = Set<String>.from(values[id] ?? const {});
    if (selected) channels.add('main');
    selected ? channels.add(channel) : channels.remove(channel);
    values[id] = channels;
    selectedEmployeeChannelAccess.assignAll(values);
  }

  void _syncEmployeeChannelAccess() {
    selectedEmployeeChannelAccess.assignAll({
      for (final employee in whatsAppEmployees)
        if (employee.channelAccess.isNotEmpty)
          employee.id: Set<String>.from(employee.channelAccess),
    });
  }

  Future<void> saveWhatsAppEmployees() async {
    actionLoading.value = true;
    try {
      final result = await api.updateWhatsAppEmployees(
          Map<int, Set<String>>.from(selectedEmployeeChannelAccess));
      final employees =
          result['employees'] is List ? result['employees'] as List : const [];
      whatsAppEmployees.assignAll(employees.whereType<Map>().map((item) =>
          WhatsAppEmployeeAccess.fromJson(Map<String, dynamic>.from(item))));
      _syncEmployeeChannelAccess();
      Get.snackbar('تم', 'تم تحديث صلاحيات مركز التواصل');
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> printQrA4() async {
    final bytes = Uint8List.fromList(
        await api.getQrPdf(accountId: selectedWhatsAppAccountId.value));
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<File> _saveQrPdf() async {
    final bytes =
        await api.getQrPdf(accountId: selectedWhatsAppAccountId.value);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/dr-bike-whatsapp-qr.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> downloadQrA4() async {
    final file = await _saveQrPdf();
    await OpenFilex.open(file.path);
  }

  Future<void> shareQrA4() async {
    final source = qrBytes.value ??
        Uint8List.fromList(
            await api.getQr(accountId: selectedWhatsAppAccountId.value));
    final picture = await svg.vg.loadPicture(svg.SvgBytesLoader(source), null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const outputSize = 1400.0;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(105, 105, 1190, 1190),
        const Radius.circular(42),
      ),
      Paint()
        ..color = const Color(0xFF075E54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18,
    );
    const targetSize = 1050.0;
    final scale = math.min(
      targetSize / picture.size.width,
      targetSize / picture.size.height,
    );
    final drawnWidth = picture.size.width * scale;
    final drawnHeight = picture.size.height * scale;
    canvas.save();
    canvas.translate(
      (outputSize - drawnWidth) / 2,
      (outputSize - drawnHeight) / 2,
    );
    canvas.scale(scale, scale);
    canvas.drawPicture(picture.picture);
    canvas.restore();
    final centeredPicture = recorder.endRecording();
    picture.picture.dispose();
    final image = await centeredPicture.toImage(1400, 1400);
    centeredPicture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw Exception('تعذر تجهيز صورة QR');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/dr-bike-whatsapp-qr.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
        text: 'تواصل مع دكتور بايك عبر واتساب');
  }

  Future<void> openChannel(SocialChannelSetting channel) async {
    final url = channel.url;
    if (url == null || url.trim().isEmpty) {
      Get.snackbar('غير متاح', 'لا يوجد رابط لهذه القناة');
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      Get.snackbar('خطأ', 'الرابط غير صالح');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareChannel(SocialChannelSetting channel) async {
    final url = channel.url;
    if (url == null || url.trim().isEmpty) {
      Get.snackbar('غير متاح', 'لا يوجد رابط للمشاركة');
      return;
    }
    await Share.share('${channel.name} دكتور بايك\n$url');
  }

  Future<void> copyChannelLink(SocialChannelSetting channel) async {
    final url = channel.url;
    if (url == null || url.trim().isEmpty) {
      Get.snackbar('غير متاح', 'لا يوجد رابط للنسخ');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url.trim()));
    Get.snackbar('تم', 'تم نسخ الرابط');
  }

  Future<bool> sendDirect(String phone, String message,
      {bool test = false}) async {
    if (phone.trim().isEmpty || message.trim().isEmpty) return false;
    actionLoading.value = true;
    try {
      final result = test
          ? await api.sendWhatsAppTestMessage(phone.trim(), message.trim(),
              accountId: selectedWhatsAppAccountId.value)
          : await api.sendWhatsAppText(phone.trim(), message.trim(),
              accountId: selectedWhatsAppAccountId.value);
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

  int? _firstConfiguredWhatsAppAccountId() {
    for (final channel in whatsAppAccountChannels) {
      final id = _accountIdFromChannel(channel);
      if (id != null && channel.configured) return id;
    }
    for (final channel in whatsAppAccountChannels) {
      final id = _accountIdFromChannel(channel);
      if (id != null) return id;
    }
    return null;
  }

  int? _accountIdFromChannel(SocialChannelSetting channel) =>
      int.tryParse(channel.details['account_id']?.toString() ?? '');

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void onClose() {
    _conversationsRefreshTimer?.cancel();
    conversationsScrollController.removeListener(_onConversationsScroll);
    conversationsScrollController.dispose();
    searchController.dispose();
    testPhoneController.dispose();
    testMessageController.dispose();
    super.onClose();
  }
}
