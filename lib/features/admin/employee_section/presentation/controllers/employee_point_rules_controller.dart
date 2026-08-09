import 'package:get/get.dart';

import '../../data/datasources/employee_datasource.dart';
import '../../domain/entities/employee_entity.dart';
import '../../data/models/employee_point_rule_model.dart';
import 'employee_service.dart';

class EmployeePointRulesController extends GetxController {
  EmployeePointRulesController({
    required this.datasource,
    required this.employeeService,
  });

  final EmployeeDatasource datasource;
  final EmployeeService employeeService;

  final RxList<EmployeePointRuleModel> rules = <EmployeePointRuleModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMutating = false.obs;
  final Rxn<Map<String, dynamic>> lastRunSummary = Rxn<Map<String, dynamic>>();

  List<EmployeeEntity> get employees => employeeService.employeeList;

  @override
  void onInit() {
    super.onInit();
    loadRules();
  }

  Future<void> loadRules() async {
    try {
      isLoading.value = true;
      rules.assignAll(await datasource.getEmployeePointRules());
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveRule({
    int? id,
    required String name,
    String? description,
    required String conditionType,
    required String periodType,
    required String operationType,
    required int defaultPoints,
    required bool appliesToAll,
    required List<int> employeeIds,
    required String cutoffTime,
    required String effectivePolicy,
    String? effectiveFrom,
    required bool isActive,
  }) async {
    try {
      isMutating.value = true;
      final payload = <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'condition_type': conditionType,
        'period_type': periodType,
        'operation_type': operationType,
        'default_points': defaultPoints,
        'applies_to_all': appliesToAll ? 1 : 0,
        if (!appliesToAll) 'employee_ids': employeeIds,
        'settings': {'cutoff_time': cutoffTime},
        'effective_policy': effectivePolicy,
        if (effectiveFrom != null && effectiveFrom.isNotEmpty)
          'effective_from': effectiveFrom,
        'is_active': isActive ? 1 : 0,
      };

      if (id == null) {
        await datasource.createEmployeePointRule(payload);
      } else {
        await datasource.updateEmployeePointRule(id, payload);
      }
      await loadRules();
      Get.snackbar('تم', 'تم حفظ قاعدة النقاط',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> toggleRule(EmployeePointRuleModel rule) async {
    await saveRule(
      id: rule.id,
      name: rule.name,
      description: rule.description,
      conditionType: rule.conditionType,
      periodType: rule.periodType,
      operationType: rule.operationType,
      defaultPoints: rule.defaultPoints,
      appliesToAll: rule.appliesToAll,
      employeeIds: rule.employeeIds,
      cutoffTime: rule.cutoffTime,
      effectivePolicy: 'from_date',
      effectiveFrom: rule.effectiveFrom,
      isActive: !rule.isActive,
    );
  }

  Future<void> deleteRule(int id) async {
    try {
      isMutating.value = true;
      await datasource.deleteEmployeePointRule(id);
      rules.removeWhere((r) => r.id == id);
      Get.snackbar('تم', 'تم حذف القاعدة', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> runRules({int? ruleId, bool force = false}) async {
    try {
      isMutating.value = true;
      lastRunSummary.value = await datasource.runEmployeePointRules(
        ruleId: ruleId,
        force: force,
      );
      Get.snackbar('تم', 'تم تشغيل قواعد النقاط',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isMutating.value = false;
    }
  }
}
