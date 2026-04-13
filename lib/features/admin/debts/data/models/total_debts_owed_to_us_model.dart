import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class TotalDebtsOwedToUsModel {
  String totalDebtsOwedToUs;

  TotalDebtsOwedToUsModel({required this.totalDebtsOwedToUs});

  factory TotalDebtsOwedToUsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return TotalDebtsOwedToUsModel(
      totalDebtsOwedToUs: asString(j[ApiKey.total_debts_owed_to_us], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {ApiKey.total_debts_owed_to_us: totalDebtsOwedToUs};
  }
}
