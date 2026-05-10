import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeeRewardRuleModel {
  const EmployeeRewardRuleModel({
    required this.id,
    required this.minPoints,
    this.maxPoints,
    required this.rewardAmount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int minPoints;
  final int? maxPoints;
  final String rewardAmount;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  double get rewardAmountDouble =>
      double.tryParse(rewardAmount.toString()) ?? 0.0;

  factory EmployeeRewardRuleModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    return EmployeeRewardRuleModel(
      id: asInt(j['id']),
      minPoints: asInt(j['min_points']),
      maxPoints: j['max_points'] == null ? null : asInt(j['max_points']),
      rewardAmount: asString(j['reward_amount'], '0.00'),
      isActive: asBool(j['is_active'], true),
      createdAt: asNullableString(j['created_at']),
      updatedAt: asNullableString(j['updated_at']),
    );
  }

  EmployeeRewardRuleModel copyWith({
    int? id,
    int? minPoints,
    int? maxPoints,
    String? rewardAmount,
    bool? isActive,
  }) {
    return EmployeeRewardRuleModel(
      id: id ?? this.id,
      minPoints: minPoints ?? this.minPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
