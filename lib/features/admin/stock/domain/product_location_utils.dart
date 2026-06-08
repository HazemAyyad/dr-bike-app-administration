import '../data/models/all_stock_products_model.dart';

/// True when the product has at least a section or shelf assigned.
bool productHasAssignedLocation(AllStockProductsModel product) {
  final section = product.storeSectionId?.trim();
  final shelf = product.shelfNumber?.trim();
  return (section != null && section.isNotEmpty) ||
      (shelf != null && shelf.isNotEmpty);
}

class SwapGroupLocationTarget {
  const SwapGroupLocationTarget({
    required this.sectionId,
    required this.sectionName,
    this.shelfNumber,
  });

  final String sectionId;
  final String sectionName;
  final String? shelfNumber;

  String get displayLabel {
    final parts = <String>[
      if (sectionName.trim().isNotEmpty) sectionName.trim(),
      if (shelfNumber != null && shelfNumber!.trim().isNotEmpty)
        shelfNumber!.trim(),
    ];
    return parts.isEmpty ? '' : parts.join(' - ');
  }
}

class SwapGroupTargets {
  const SwapGroupTargets({
    this.groupA,
    this.groupB,
  });

  final SwapGroupLocationTarget? groupA;
  final SwapGroupLocationTarget? groupB;

  bool get isComplete => groupA != null && groupB != null;
}

String groupTargetLabel(
  SwapGroupLocationTarget? target, {
  required String unsetLabel,
}) {
  if (target == null || target.displayLabel.isEmpty) {
    return unsetLabel;
  }
  return target.displayLabel;
}
