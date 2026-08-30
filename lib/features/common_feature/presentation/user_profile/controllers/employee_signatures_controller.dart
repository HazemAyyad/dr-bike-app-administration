import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';

class EmployeeSignatureModel {
  const EmployeeSignatureModel(
      {required this.id,
      required this.name,
      required this.source,
      required this.processedPath,
      required this.isDefault,
      required this.approvedAt});
  final int id;
  final String name;
  final String source;
  final String processedPath;
  final bool isDefault;
  final String approvedAt;

  factory EmployeeSignatureModel.fromJson(Map<String, dynamic> json) =>
      EmployeeSignatureModel(
        id: int.tryParse('${json['id']}') ?? 0,
        name: '${json['name'] ?? ''}',
        source: '${json['source'] ?? ''}',
        processedPath: '${json['processed_path'] ?? ''}',
        isDefault: json['is_default'] == true || '${json['is_default']}' == '1',
        approvedAt: '${json['approved_at'] ?? ''}',
      );

  String get imageUrl {
    final relative = processedPath.startsWith('public/')
        ? processedPath.substring(7)
        : processedPath;
    return '${EndPoints.baserUrlForImage}$relative';
  }
}

class EmployeeSignaturesController extends GetxController {
  EmployeeSignaturesController(this.api);
  final DioConsumer api;
  final signatures = <EmployeeSignatureModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final actionId = RxnInt();

  EmployeeSignatureModel? get defaultSignature =>
      signatures.firstWhereOrNull((item) => item.isDefault);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await api.get(EndPoints.employeeSignatures);
      _ensureSuccess(response.data);
      final raw = response.data['signatures'];
      signatures.assignAll(raw is List
          ? raw.whereType<Map>().map((row) =>
              EmployeeSignatureModel.fromJson(Map<String, dynamic>.from(row)))
          : const []);
    } catch (error) {
      Get.snackbar('تعذر تحميل التوقيعات', _message(error));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> create(
      {required String name,
      required String source,
      required Uint8List originalBytes,
      required bool isDefault}) async {
    if (name.trim().isEmpty) {
      Get.snackbar('اسم التوقيع مطلوب', 'اكتب اسمًا يميز هذا التوقيع');
      return false;
    }
    isSaving.value = true;
    try {
      final jpeg = originalBytes.length > 2 &&
          originalBytes[0] == 0xff &&
          originalBytes[1] == 0xd8;
      final response = await api.post(EndPoints.employeeSignatures, data: {
        'name': name.trim(),
        'source': source,
        'is_default': isDefault,
        'signature':
            'data:image/${jpeg ? 'jpeg' : 'png'};base64,${base64Encode(originalBytes)}',
      });
      _ensureSuccess(response.data);
      await load();
      Get.snackbar('تم حفظ التوقيع', '${response.data['message'] ?? ''}');
      return true;
    } catch (error) {
      Get.snackbar('تعذر حفظ التوقيع', _message(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> makeDefault(EmployeeSignatureModel signature) async {
    actionId.value = signature.id;
    try {
      final response = await api.patch(
          EndPoints.employeeSignature(signature.id),
          data: {'is_default': true});
      _ensureSuccess(response.data);
      await load();
      Get.snackbar('تم التحديث', 'أصبح ${signature.name} هو التوقيع الافتراضي');
    } catch (error) {
      Get.snackbar('تعذر تغيير الافتراضي', _message(error));
    } finally {
      actionId.value = null;
    }
  }

  Future<void> rename(EmployeeSignatureModel signature, String name) async {
    if (name.trim().isEmpty) return;
    actionId.value = signature.id;
    try {
      final response = await api.patch(
          EndPoints.employeeSignature(signature.id),
          data: {'name': name.trim()});
      _ensureSuccess(response.data);
      await load();
    } catch (error) {
      Get.snackbar('تعذر تعديل الاسم', _message(error));
    } finally {
      actionId.value = null;
    }
  }

  Future<void> deleteSignature(EmployeeSignatureModel signature) async {
    actionId.value = signature.id;
    try {
      final response =
          await api.delete(EndPoints.employeeSignature(signature.id));
      _ensureSuccess(response.data);
      await load();
      Get.snackbar('تم الحذف', 'تم حذف التوقيع من ملفك');
    } catch (error) {
      Get.snackbar('تعذر حذف التوقيع', _message(error));
    } finally {
      actionId.value = null;
    }
  }

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['status'] != 'success') {
      final errors = data['errors'];
      final first = errors is Map && errors.isNotEmpty
          ? errors.values.first
          : data['message'];
      throw Exception(first is List && first.isNotEmpty ? first.first : first);
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
