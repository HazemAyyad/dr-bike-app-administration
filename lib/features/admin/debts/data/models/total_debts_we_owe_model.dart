import 'package:doctorbike/core/databases/api/end_points.dart';

class TotalDebtsWeOweModel {
  final String totalDebtsWeOwe;

  TotalDebtsWeOweModel({required this.totalDebtsWeOwe});

  factory TotalDebtsWeOweModel.fromJson(Map<String, dynamic> json) {
    return TotalDebtsWeOweModel(
      totalDebtsWeOwe: (json[ApiKey.total_debts_we_owe] ?? '0').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {ApiKey.total_debts_we_owe: totalDebtsWeOwe};
  }
}
