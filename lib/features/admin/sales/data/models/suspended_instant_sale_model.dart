import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class SuspendedInstantSaleNote {
  final String id;
  final String note;
  final int? userId;
  final String userName;
  final String createdAt;

  const SuspendedInstantSaleNote({
    required this.id,
    required this.note,
    this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory SuspendedInstantSaleNote.fromJson(Map<String, dynamic> json) {
    return SuspendedInstantSaleNote(
      id: asString(json['id']),
      note: asString(json['note']),
      userId: json['user_id'] == null ? null : asInt(json['user_id']),
      userName: asString(json['user_name'], '-'),
      createdAt: asString(json['created_at']),
    );
  }
}

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
  final List<SuspendedInstantSaleNote> noteLog;
  final SuspendedInstantSaleNote? latestNote;
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
    this.noteLog = const [],
    this.latestNote,
    required this.payload,
  });

  bool get isCheckoutStep => currentStep == 'checkout';
  int get noteCount => noteLog.length;

  factory SuspendedInstantSaleModel.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    final noteRows = extractMapListFromResponse(json, 'note_log')
        .map((row) => SuspendedInstantSaleNote.fromJson(row))
        .toList();
    final latestRaw = json['latest_note'];
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
      noteLog: noteRows,
      latestNote: latestRaw is Map
          ? SuspendedInstantSaleNote.fromJson(
              Map<String, dynamic>.from(latestRaw),
            )
          : noteRows.isEmpty
              ? null
              : noteRows.last,
      payload: payloadRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(payloadRaw)
          : payloadRaw is Map
              ? Map<String, dynamic>.from(payloadRaw)
              : <String, dynamic>{},
    );
  }
}
