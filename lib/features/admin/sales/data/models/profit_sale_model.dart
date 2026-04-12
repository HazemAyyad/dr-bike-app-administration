import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProfitSale {
  final int id;
  final String totalCost;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfitSale({
    required this.id,
    required this.totalCost,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfitSale.fromJson(Map<String, dynamic> json) {
    return ProfitSale(
      id: asInt(json['id']),
      totalCost: asString(json['total_cost'], '0'),
      notes: asString(json['notes'], 'no notes'),
      createdAt: parseApiDateTime(json['created_at']),
      updatedAt: parseApiDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_cost': totalCost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
