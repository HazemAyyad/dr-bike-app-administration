import 'package:doctorbike/core/databases/api/end_points.dart';

class TotalDebtsOwedToUsModel {
  String totalDebtsOwedToUs;

  TotalDebtsOwedToUsModel({required this.totalDebtsOwedToUs});

  factory TotalDebtsOwedToUsModel.fromJson(Map<String, dynamic> json) {
    return TotalDebtsOwedToUsModel(
      totalDebtsOwedToUs: json[ApiKey.total_debts_owed_to_us] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {ApiKey.total_debts_owed_to_us: totalDebtsOwedToUs};
  }
}
