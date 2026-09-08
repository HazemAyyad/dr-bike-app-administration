import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_reward_rule_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
class EmployeeRewardRulesController extends GetxController {
  EmployeeRewardRulesController({
    required this.fetchRulesUsecase,
    required this.createRuleUsecase,
    required this.updateRuleUsecase,
    required this.deleteRuleUsecase,
  });

  final GetEmployeeRewardRulesUsecase fetchRulesUsecase;
  final CreateEmployeeRewardRuleUsecase createRuleUsecase;
  final UpdateEmployeeRewardRuleUsecase updateRuleUsecase;
  final DeleteEmployeeRewardRuleUsecase deleteRuleUsecase;

  final RxList<EmployeeRewardRuleModel> rules = <EmployeeRewardRuleModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMutating = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadRules();
  }

  Future<void> loadRules() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      rules.assignAll(await fetchRulesUsecase.call());
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
      AppFailureNotice.show(
        title: 'error'.tr,
        message: e.errMessage,
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createRule({
    required int minPoints,
    int? maxPoints,
    required double rewardAmount,
    required bool isActive,
    String? statusLabel,
    String? statusColor,
  }) async {
    isMutating.value = true;
    try {
      final result = await createRuleUsecase.call(
        minPoints: minPoints,
        maxPoints: maxPoints,
        rewardAmount: rewardAmount,
        isActive: isActive,
        statusLabel: statusLabel,
        statusColor: statusColor,
      );
      return result.fold(
        (failure) {
          AppFailureNotice.show(
            title: 'error'.tr,
            message: failure.errMessage,
          );
          return false;
        },
        (_) {
          loadRules();
          AppSuccessNotice.show(
            title: 'success'.tr,
            message: 'rewardRuleCreated'.tr,
          );
          return true;
        },
      );
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> updateRule({
    required int id,
    int? minPoints,
    int? maxPoints,
    bool clearMaxPoints = false,
    double? rewardAmount,
    String? statusLabel,
    String? statusColor,
    bool clearStatusFields = false,
    bool? isActive,
  }) async {
    isMutating.value = true;
    try {
      final result = await updateRuleUsecase.call(
        id: id,
        minPoints: minPoints,
        maxPoints: maxPoints,
        clearMaxPoints: clearMaxPoints,
        rewardAmount: rewardAmount,
        statusLabel: statusLabel,
        statusColor: statusColor,
        clearStatusFields: clearStatusFields,
        isActive: isActive,
      );
      return result.fold(
        (failure) {
          AppFailureNotice.show(
            title: 'error'.tr,
            message: failure.errMessage,
          );
          return false;
        },
        (rule) {
          final index = rules.indexWhere((r) => r.id == rule.id);
          if (index >= 0) {
            rules[index] = rule;
          } else {
            loadRules();
          }
          AppSuccessNotice.show(
            title: 'success'.tr,
            message: 'rewardRuleUpdated'.tr,
          );
          return true;
        },
      );
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> toggleActive(EmployeeRewardRuleModel rule) {
    return updateRule(id: rule.id, isActive: !rule.isActive);
  }

  Future<bool> deleteRule(int id) async {
    isMutating.value = true;
    try {
      final result = await deleteRuleUsecase.call(id: id);
      return result.fold(
        (failure) {
          AppFailureNotice.show(
            title: 'error'.tr,
            message: failure.errMessage,
          );
          return false;
        },
        (_) {
          rules.removeWhere((r) => r.id == id);
          AppSuccessNotice.show(
            title: 'success'.tr,
            message: 'rewardRuleDeleted'.tr,
          );
          return true;
        },
      );
    } finally {
      isMutating.value = false;
    }
  }
}
