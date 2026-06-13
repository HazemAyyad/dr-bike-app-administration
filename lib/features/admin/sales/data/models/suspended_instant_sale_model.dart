import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class SuspendedInstantSaleModel {
  final int id;
  final String referenceCode;
  final String currentStep;
  final String summaryLabel;
  final double totalCost;
  final String status;
  final String? suspendedAt;
  final int? createdByUserId;
  final String? createdByName;
  final int? employeeId;
  final String? employeeName;
  final Map<String, dynamic> payload;

  const SuspendedInstantSaleModel({
    required this.id,
    required this.referenceCode,
    required this.currentStep,
    required this.summaryLabel,
    required this.totalCost,
    required this.status,
    this.suspendedAt,
    this.createdByUserId,
    this.createdByName,
    this.employeeId,
    this.employeeName,
    required this.payload,
  });

  bool get isCheckoutStep => currentStep == 'checkout';

  factory SuspendedInstantSaleModel.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    return SuspendedInstantSaleModel(
      id: asInt(json['id']),
      referenceCode: asString(json['reference_code'], 'ع-${asInt(json['id'])}'),
      currentStep: asString(json['current_step'], 'product_picker'),
      summaryLabel: asString(json['summary_label'], ''),
      totalCost: asDouble(json['total_cost']),
      status: asString(json['status'], 'suspended'),
      suspendedAt: json['suspended_at']?.toString(),
      createdByUserId: json['created_by_user_id'] == null
          ? null
          : asInt(json['created_by_user_id']),
      createdByName: json['created_by_name']?.toString(),
      employeeId:
          json['employee_id'] == null ? null : asInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      payload: payloadRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(payloadRaw)
          : payloadRaw is Map
              ? Map<String, dynamic>.from(payloadRaw)
              : <String, dynamic>{},
    );
  }
}
