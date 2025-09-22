import 'all_boxes_logs_entity.dart';

class BoxDetailsEntity {
  final String boxName;
  final String totalBalance;
  final String isShown;
  final List<BoxLog> boxLogs;
  final String currency;

  BoxDetailsEntity({
    required this.boxName,
    required this.totalBalance,
    required this.isShown,
    required this.boxLogs,
    required this.currency,
  });
}
