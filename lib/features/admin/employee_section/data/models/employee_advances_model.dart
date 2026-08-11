import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeeAdvanceModel {
  const EmployeeAdvanceModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.day,
    required this.date,
    required this.time,
    this.approvedLoanValue,
    this.reviewedAt,
    this.rejectionReason,
    this.approvedBoxName,
    this.cancellationReason,
    this.cancelledAt,
    this.previousLoanValue,
    this.editedAfterApprovalAt,
    this.canEdit = false,
    this.canCancel = false,
  });

  final int id;
  final String status;
  final String amount;
  final String day;
  final String date;
  final String time;
  final String? approvedLoanValue;
  final String? reviewedAt;
  final String? rejectionReason;
  final String? approvedBoxName;
  final String? cancellationReason;
  final String? cancelledAt;
  final String? previousLoanValue;
  final String? editedAfterApprovalAt;
  final bool canEdit;
  final bool canCancel;

  factory EmployeeAdvanceModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAdvanceModel(
      id: asInt(json['id']),
      status: asString(json['status'], 'pending'),
      amount: asString(json['amount'], '0'),
      day: asString(json['day']),
      date: asString(json['date']),
      time: asString(json['time']),
      approvedLoanValue: asNullableString(json['approved_loan_value']),
      reviewedAt: asNullableString(json['reviewed_at']),
      rejectionReason: asNullableString(json['rejection_reason']),
      approvedBoxName: asNullableString(json['approved_box_name']),
      cancellationReason: asNullableString(json['cancellation_reason']),
      cancelledAt: asNullableString(json['cancelled_at']),
      previousLoanValue: asNullableString(json['previous_loan_value']),
      editedAfterApprovalAt: asNullableString(json['edited_after_approval_at']),
      canEdit: json['can_edit'] == true,
      canCancel: json['can_cancel'] == true,
    );
  }
}

class EmployeeAdvancesResult {
  const EmployeeAdvancesResult({
    required this.month,
    required this.advances,
    required this.total,
    required this.approvedTotal,
  });

  final String month;
  final List<EmployeeAdvanceModel> advances;
  final String total;
  final String approvedTotal;

  factory EmployeeAdvancesResult.fromJson(Map<String, dynamic> json) {
    final data = asMap(json['data']);
    final rawAdvances = data['advances'];
    final advances = rawAdvances is List
        ? rawAdvances
            .whereType<Map>()
            .map((e) => EmployeeAdvanceModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <EmployeeAdvanceModel>[];

    return EmployeeAdvancesResult(
      month: asString(data['month']),
      advances: advances,
      total: asString(data['total'], '0'),
      approvedTotal: asString(data['approved_total'], '0'),
    );
  }
}
