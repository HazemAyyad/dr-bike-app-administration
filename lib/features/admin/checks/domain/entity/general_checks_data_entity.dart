class GeneralChecksDataEntity {
  final int notCashedOutgoingChecksCount;
  final int cashedOutgoingChecksCount;
  final int notCashedIncomingChecksCount;
  final int cashedIncomingChecksCount;
  final int cashedToBoxIncomingChecksCount;

  final String totalOutgoingChecksDollar;
  final String totalOutgoingChecksDinar;
  final String totalOutgoingChecksShekel;

  final String totalIncomingChecksDollar;
  final String totalIncomingChecksDinar;
  final String totalIncomingChecksShekel;

  const GeneralChecksDataEntity({
    required this.notCashedOutgoingChecksCount,
    required this.cashedOutgoingChecksCount,
    required this.notCashedIncomingChecksCount,
    required this.cashedIncomingChecksCount,
    required this.cashedToBoxIncomingChecksCount,
    required this.totalOutgoingChecksDollar,
    required this.totalOutgoingChecksDinar,
    required this.totalOutgoingChecksShekel,
    required this.totalIncomingChecksDollar,
    required this.totalIncomingChecksDinar,
    required this.totalIncomingChecksShekel,
  });
}
