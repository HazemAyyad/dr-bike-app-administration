import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class ExpenseModel {
  final int id;
  final String name;
  final String price;
  final DateTime createdAt;
  final String? image;
  final String expenseType;
  final int? salaryPeriodId;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
    this.image,
    this.expenseType = 'general',
    this.salaryPeriodId,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ExpenseModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      price: asString(j['price'], '0.0'),
      createdAt: parseApiDateTime(j['created_at']),
      image: ShowNetImage.getPhoto(asNullableString(j['image'])),
      expenseType: asString(j['expense_type'], 'general'),
      salaryPeriodId:
          j['salary_period_id'] == null ? null : asInt(j['salary_period_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'image': image,
      'expense_type': expenseType,
      'salary_period_id': salaryPeriodId,
    };
  }
}
