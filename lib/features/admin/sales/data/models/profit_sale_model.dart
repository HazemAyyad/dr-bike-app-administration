class ProfitSale {
  final int id;
  final String totalCost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfitSale({
    required this.id,
    required this.totalCost,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfitSale.fromJson(Map<String, dynamic> json) {
    return ProfitSale(
      id: json['id'] ?? 0,
      totalCost: json['total_cost'] ?? '0',
      notes: json['notes'] ?? 'no notes',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
