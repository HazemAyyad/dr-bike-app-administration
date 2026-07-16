import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:get/get.dart';

class StockMovementSummary {
  final int totalIn;
  final int totalOut;
  final int currentStock;

  const StockMovementSummary({
    required this.totalIn,
    required this.totalOut,
    required this.currentStock,
  });

  factory StockMovementSummary.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return StockMovementSummary(
      totalIn: asInt(j['total_in']),
      totalOut: asInt(j['total_out']),
      currentStock: asInt(j['current_stock']),
    );
  }
}

class ProductStockMovementModel {
  final String id;
  final String type;
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final double? unitCost;
  final double? totalCost;
  final String? size;
  final String? colorAr;
  final String? note;
  final String? referenceType;
  final String? referenceId;
  final String? invoiceNumber;
  final String? createdByName;
  final String? createdAt;

  const ProductStockMovementModel({
    required this.id,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.unitCost,
    this.totalCost,
    this.size,
    this.colorAr,
    this.note,
    this.referenceType,
    this.referenceId,
    this.invoiceNumber,
    this.createdByName,
    this.createdAt,
  });

  bool get isSaleRelated => type == 'sale' || type == 'sale_cancel';

  bool get hasInvoiceLink =>
      isSaleRelated &&
      referenceType == 'instant_sale' &&
      referenceId != null &&
      referenceId!.isNotEmpty;

  String get displayInvoiceNumber =>
      invoiceNumber ??
      (referenceId != null && referenceId!.isNotEmpty ? '#$referenceId' : '');

  String movementTypeLabel() {
    const keys = {
      'purchase': 'stockMoveTypePurchase',
      'bill_quantity': 'stockMoveTypeBillQuantity',
      'sale': 'stockMoveTypeSale',
      'sale_cancel': 'stockMoveTypeSaleCancel',
      'destruction': 'stockMoveTypeDestruction',
      'return': 'stockMoveTypeReturn',
      'manual_add': 'stockMoveTypeManualAdd',
      'manual_set': 'stockMoveTypeManualSet',
      'import': 'stockMoveTypeImport',
      'assembly_component': 'stockMoveTypeAssemblyComponent',
      'assembly_output': 'stockMoveTypeAssemblyOutput',
      'disassembly_component': 'stockMoveTypeDisassemblyComponent',
      'disassembly_output': 'stockMoveTypeDisassemblyOutput',
    };
    final key = keys[type];
    return key != null ? key.tr : type;
  }

  factory ProductStockMovementModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductStockMovementModel(
      id: asString(j['id']),
      type: asString(j['type']),
      quantity: asInt(j['quantity']),
      stockBefore: asInt(j['stock_before']),
      stockAfter: asInt(j['stock_after']),
      unitCost: j['unit_cost'] == null ? null : asDouble(j['unit_cost']),
      totalCost: j['total_cost'] == null ? null : asDouble(j['total_cost']),
      size: asNullableString(j['size']),
      colorAr: asNullableString(j['color_ar']),
      note: asNullableString(j['note']),
      referenceType: asNullableString(j['reference_type']),
      referenceId: asNullableString(j['reference_id']),
      invoiceNumber: asNullableString(j['invoice_number']),
      createdByName: asNullableString(j['created_by_name']),
      createdAt: asNullableString(j['created_at']),
    );
  }
}

class StockMovementsPageResult {
  final StockMovementSummary summary;
  final List<ProductStockMovementModel> movements;
  final int currentPage;
  final int lastPage;
  final int total;

  const StockMovementsPageResult({
    required this.summary,
    required this.movements,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory StockMovementsPageResult.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final pagination = asMap(j['pagination']);
    return StockMovementsPageResult(
      summary: StockMovementSummary.fromJson(asMap(j['summary'])),
      movements: mapList(
        j['movements'],
        (m) => ProductStockMovementModel.fromJson(m),
      ),
      currentPage: asInt(pagination['current_page'], 1),
      lastPage: asInt(pagination['last_page'], 1),
      total: asInt(pagination['total']),
    );
  }
}
