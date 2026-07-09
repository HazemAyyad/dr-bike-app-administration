class Box {
  final int id;
  final String name;
  final double total;
  final String type;

  const Box({
    required this.id,
    required this.name,
    required this.total,
    required this.type,
  });
}

class BoxLog {
  final int id;
  final String? fromBoxId;
  final String? toBoxId;
  final String description;
  final String? note;
  final double value;
  final String? boxId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? type;
  final String? maintenanceId;
  final String? instantSaleId;
  final String? invoiceNumber;
  final double? boxBalanceBefore;
  final double? boxBalanceAfter;

  final Box? fromBox;
  final Box? toBox;
  final Box? box;

  const BoxLog({
    required this.id,
    this.fromBoxId,
    this.toBoxId,
    required this.description,
    this.note,
    required this.value,
    this.boxId,
    required this.createdAt,
    required this.updatedAt,
    this.type,
    this.maintenanceId,
    this.instantSaleId,
    this.invoiceNumber,
    this.boxBalanceBefore,
    this.boxBalanceAfter,
    this.fromBox,
    this.toBox,
    this.box,
  });
}
