class GetShownBoxesEntity {
  final int boxId;
  final String boxName;
  final double totalBalance;
  final bool isShown;
  final String currency;

  const GetShownBoxesEntity({
    required this.boxId,
    required this.boxName,
    required this.totalBalance,
    required this.isShown,
    required this.currency,
  });
}
