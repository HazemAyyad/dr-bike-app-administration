class Box {
  final int id;
  final String name;
  final double total;

  const Box({
    required this.id,
    required this.name,
    required this.total,
  });
}

class BoxLog {
  final int id;
  final String? fromBoxId;
  final String? toBoxId;
  final String description;
  final double value;
  final String? boxId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? type;

  final Box? fromBox;
  final Box? toBox;
  final Box? box;

  const BoxLog({
    required this.id,
    this.fromBoxId,
    this.toBoxId,
    required this.description,
    required this.value,
    this.boxId,
    required this.createdAt,
    required this.updatedAt,
    this.type,
    this.fromBox,
    this.toBox,
    this.box,
  });
}
