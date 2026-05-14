import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeeAdvanceModel {
  const EmployeeAdvanceModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.day,
    required this.date,
    required this.time,
  });

  final int id;
  final String status;
  final String amount;
  final String day;
  final String date;
  final String time;

  factory EmployeeAdvanceModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAdvanceModel(
      id: asInt(json['id']),
      status: asString(json['status'], 'pending'),
      amount: asString(json['amount'], '0'),
      day: asString(json['day']),
      date: asString(json['date']),
      time: asString(json['time']),
    );
  }
}

class EmployeeAdvancesResult {
  const EmployeeAdvancesResult({
    required this.month,
    required this.advances,
    required this.total,
  });

  final String month;
  final List<EmployeeAdvanceModel> advances;
  final String total;

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
    );
  }
}
