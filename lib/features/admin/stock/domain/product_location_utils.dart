import '../data/models/all_stock_products_model.dart';

/// API / filter sentinel for products without an assigned store section.
const kUnassignedStoreSectionFilterId = 'none';

bool isUnassignedStoreSectionFilter(String? sectionId) =>
    sectionId == kUnassignedStoreSectionFilterId;

/// True when the product has a store section assigned.
bool productHasAssignedLocation(AllStockProductsModel product) {
  final section = product.storeSectionId?.trim();
  return section != null && section.isNotEmpty;
}

class SwapGroupLocationTarget {
  const SwapGroupLocationTarget({
    required this.sectionId,
    required this.sectionName,
  });

  final String sectionId;
  final String sectionName;

  String get displayLabel =>
      sectionName.trim().isNotEmpty ? sectionName.trim() : '';
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
