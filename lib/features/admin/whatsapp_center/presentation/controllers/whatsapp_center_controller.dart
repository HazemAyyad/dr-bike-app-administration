// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart' as svg;

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
  final whatsAppEmployees = <WhatsAppEmployeeAccess>[].obs;
  final selectedWhatsAppEmployeeIds = <int>{}.obs;
  final canManageWhatsAppEmployees = false.obs;
  final qrBytes = Rxn<Uint8List>();
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
        final result = await api.getWhatsAppSettings();
        settings.value = WhatsAppSettings.fromJson(result);
        canManageWhatsAppEmployees.value =
            result['can_manage_employees'] == true;
        final employees = result['employees'] is List
            ? result['employees'] as List
            : const [];
        whatsAppEmployees.assignAll(employees.whereType<Map>().map((item) =>
            WhatsAppEmployeeAccess.fromJson(Map<String, dynamic>.from(item))));
        selectedWhatsAppEmployeeIds.assignAll(whatsAppEmployees
            .where((employee) => employee.hasAccess)
            .map((employee) => employee.id));
        try {
          qrBytes.value = Uint8List.fromList(await api.getQr());
        } catch (_) {
          qrBytes.value = null;
        }
      });

  void toggleWhatsAppEmployee(int id, bool selected) {
    final values = Set<int>.from(selectedWhatsAppEmployeeIds);
    selected ? values.add(id) : values.remove(id);
    selectedWhatsAppEmployeeIds.assignAll(values);
  }

  Future<void> saveWhatsAppEmployees() async {
    actionLoading.value = true;
    try {
      final result = await api
          .updateWhatsAppEmployees(selectedWhatsAppEmployeeIds.toList());
      final employees =
          result['employees'] is List ? result['employees'] as List : const [];
      whatsAppEmployees.assignAll(employees.whereType<Map>().map((item) =>
          WhatsAppEmployeeAccess.fromJson(Map<String, dynamic>.from(item))));
      selectedWhatsAppEmployeeIds.assignAll(whatsAppEmployees
          .where((employee) => employee.hasAccess)
          .map((employee) => employee.id));
      Get.snackbar('تم', 'تم تحديث صلاحيات قسم واتساب');
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> printQrA4() async {
    final bytes = Uint8List.fromList(await api.getQrPdf());
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<File> _saveQrPdf() async {
    final bytes = await api.getQrPdf();
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
    final source = qrBytes.value ?? Uint8List.fromList(await api.getQr());
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
