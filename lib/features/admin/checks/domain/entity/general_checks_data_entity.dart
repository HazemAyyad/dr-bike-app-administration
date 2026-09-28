class GeneralChecksDataEntity {
  final int notCashedOutgoingChecksCount;
  final int cashedOutgoingChecksCount;
  final int scheduledOutgoingChecksCount;
  final int partiallyPaidOutgoingChecksCount;
  final int paidOutgoingChecksCount;
  final int notCashedIncomingChecksCount;
  final int cashedIncomingChecksCount;
  final int cashedToBoxIncomingChecksCount;

  final String totalOutgoingChecksDollar;
  final String totalOutgoingChecksDinar;
  final String totalOutgoingChecksShekel;
  final String paidOutgoingChecksDollar;
  final String paidOutgoingChecksDinar;
  final String paidOutgoingChecksShekel;

  final String totalIncomingChecksDollar;
  final String totalIncomingChecksDinar;
  final String totalIncomingChecksShekel;

  const GeneralChecksDataEntity({
    required this.notCashedOutgoingChecksCount,
    required this.cashedOutgoingChecksCount,
    required this.scheduledOutgoingChecksCount,
    required this.partiallyPaidOutgoingChecksCount,
    required this.paidOutgoingChecksCount,
    required this.notCashedIncomingChecksCount,
    required this.cashedIncomingChecksCount,
    required this.cashedToBoxIncomingChecksCount,
    required this.totalOutgoingChecksDollar,
    required this.totalOutgoingChecksDinar,
    required this.totalOutgoingChecksShekel,
    required this.paidOutgoingChecksDollar,
    required this.paidOutgoingChecksDinar,
    required this.paidOutgoingChecksShekel,
    required this.totalIncomingChecksDollar,
    required this.totalIncomingChecksDinar,
    required this.totalIncomingChecksShekel,
  });
}
