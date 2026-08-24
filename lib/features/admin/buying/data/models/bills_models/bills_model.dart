import 'package:doctorbike/core/helpers/json_safe_parser.dart';

String _billSellerString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is num) return v.toString();
  if (v is Map) {
    final m = Map<String, dynamic>.from(v);
    if (m['name'] != null) return asString(m['name']);
    if (m['seller_name'] != null) return asString(m['seller_name']);
    final user = m['user'];
    if (user is Map) {
      final um = Map<String, dynamic>.from(user);
      if (um['name'] != null) return asString(um['name']);
    }
  }
  return asString(v);
}

String _billCreatedAtString(dynamic v) {
  if (v == null) return DateTime.now().toIso8601String();
  if (v is String) {
    if (v.isEmpty) return DateTime.now().toIso8601String();
    return v;
  }
  return parseApiDateTime(v).toIso8601String();
}

class BillDataModel {
  final int id;
  final String total;
  final String seller;
  final String sourceType;
  final String createdAt;
  final String status;
  final String workflowStatus;
  final String paymentStatus;
  final String finalTotal;
  final String paidAmount;
  final String remainingAmount;
  final String currency;
  final int itemsCount;
  final int receivingIssuesCount;
  final num missingQuantityTotal;
  final num extraQuantityTotal;
  final num damagedQuantityTotal;
  final num mismatchedQuantityTotal;

  BillDataModel({
    required this.id,
    required this.total,
    required this.seller,
    required this.sourceType,
    required this.createdAt,
    required this.status,
    required this.workflowStatus,
    required this.paymentStatus,
    required this.finalTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.currency,
    required this.itemsCount,
    required this.receivingIssuesCount,
    required this.missingQuantityTotal,
    required this.extraQuantityTotal,
    required this.damagedQuantityTotal,
    required this.mismatchedQuantityTotal,
  });

  factory BillDataModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);

    return BillDataModel(
      id: asInt(j['id']),
      total: asString(
        j['total'] ?? j['total_amount'] ?? j['amount'],
        '0.0',
      ),
      seller: _billSellerString(
        j['seller'] ?? j['seller_name'] ?? j['user'],
      ),
      sourceType: asString(j['source_type']),
      createdAt: _billCreatedAtString(
        j['created_at'] ?? j['date'] ?? j['createdAt'],
      ),
      status: asString(j['status']),
      workflowStatus: asString(j['workflow_status']),
      paymentStatus: asString(j['payment_status'], 'unpaid'),
      finalTotal: asString(j['final_total'], asString(j['total'], '0.0')),
      paidAmount: asString(j['paid_amount'], '0'),
      remainingAmount: asString(j['remaining_amount'], '0'),
      currency: asString(j['currency'], 'شيكل'),
      itemsCount: asInt(j['items_count']),
      receivingIssuesCount: asInt(j['receiving_issues_count']),
      missingQuantityTotal: asDouble(j['missing_quantity_total']),
      extraQuantityTotal: asDouble(j['extra_quantity_total']),
      damagedQuantityTotal: asDouble(j['damaged_quantity_total']),
      mismatchedQuantityTotal: asDouble(j['mismatched_quantity_total']),
    );
  }

  bool get canQuickPay =>
      workflowStatus == 'finalized' &&
      paymentStatus != 'paid' &&
      (double.tryParse(remainingAmount) ?? 0) > 0;

  bool get hasReceivingSummary =>
      receivingIssuesCount > 0 ||
      missingQuantityTotal > 0 ||
      extraQuantityTotal > 0 ||
      damagedQuantityTotal > 0 ||
      mismatchedQuantityTotal > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'seller': seller,
      'source_type': sourceType,
      'created_at': createdAt,
      'status': status,
      'workflow_status': workflowStatus,
      'payment_status': paymentStatus,
      'final_total': finalTotal,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'currency': currency,
      'items_count': itemsCount,
      'receiving_issues_count': receivingIssuesCount,
      'missing_quantity_total': missingQuantityTotal,
      'extra_quantity_total': extraQuantityTotal,
      'damaged_quantity_total': damagedQuantityTotal,
      'mismatched_quantity_total': mismatchedQuantityTotal,
    };
  }
}
