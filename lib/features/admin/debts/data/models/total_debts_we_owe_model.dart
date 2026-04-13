import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class TotalDebtsWeOweModel {
  final String totalDebtsWeOwe;

  TotalDebtsWeOweModel({required this.totalDebtsWeOwe});

  factory TotalDebtsWeOweModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return TotalDebtsWeOweModel(
      totalDebtsWeOwe: asString(j[ApiKey.total_debts_we_owe], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {ApiKey.total_debts_we_owe: totalDebtsWeOwe};
  }
}
