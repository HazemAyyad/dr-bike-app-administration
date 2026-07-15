import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import '../utils/sale_variant_display.dart';

class InstantSalesModel {
  final int id;
  final String? invoiceNumberValue;
  final String? serialNumber;
  final int? maintenanceId;
  final String? maintenanceInvoiceNumber;
  final String saleKind;
  final String? saleKindLabelAr;
  final String product;
  final String? productBase;
  final String cost;
  final String totalCost;
  final String quantity;
  final DateTime date;
  final DateTime? createdAt;
  final String notes;
  final List<SubProductsModel> subProducts;
  final String? buyerType;
  final String? buyerTypeLabelAr;
  final int? buyerId;
  final String? buyerName;
  final String? buyerPhone;
  final String? projectName;
  final String? status;
  final String? paymentBoxName;
  final String? paymentBoxValue;
  final String paidAmount;
  final String remainingAmount;
  final bool isPackageSale;
  final int? offerPackageId;
  final String? packageName;
  final String saleType;
  final String saleComposition;
  final bool hasAdditionalProducts;
  final int? createdBy;
  final String? createdByName;
  final int? updatedBy;
  final String? updatedByName;
  final String? sizeLabel;
  final String? colorLabel;
  final String? variantLabel;

  const InstantSalesModel({
    required this.id,
    this.invoiceNumberValue,
    this.serialNumber,
    this.maintenanceId,
    this.maintenanceInvoiceNumber,
    this.saleKind = 'regular',
    this.saleKindLabelAr,
    required this.product,
    this.productBase,
    required this.cost,
    required this.totalCost,
    required this.quantity,
    required this.date,
    this.createdAt,
    required this.notes,
    this.subProducts = const [],
    this.buyerType,
    this.buyerTypeLabelAr,
    this.buyerId,
    this.buyerName,
    this.buyerPhone,
    this.projectName,
    this.status,
    this.paymentBoxName,
    this.paymentBoxValue,
    this.paidAmount = '0',
    this.remainingAmount = '0',
    this.isPackageSale = false,
    this.offerPackageId,
    this.packageName,
    this.saleType = 'product',
    this.saleComposition = 'product',
    this.hasAdditionalProducts = false,
    this.createdBy,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
    this.sizeLabel,
    this.colorLabel,
    this.variantLabel,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isAdjustmentSale => saleKind == 'adjustment';

  double get paidAmountValue =>
      double.tryParse(paidAmount) ??
      double.tryParse(paymentBoxValue ?? '') ??
      0;

  double get remainingAmountValue {
    final fromApi = double.tryParse(remainingAmount);
    if (fromApi != null) return fromApi;
    final total = double.tryParse(totalCost) ?? 0;
    return (total - paidAmountValue).clamp(0, double.infinity);
  }

  bool get hasDebtRemaining => remainingAmountValue > 0.01;

  /// `product` | `package` | `mixed`
  String get compositionKind {
    if (!isPackageSale) return 'product';
    if (hasAdditionalProducts || additionalProductLines.isNotEmpty) {
      return 'mixed';
    }
    if (saleComposition == 'mixed' || saleComposition == 'package') {
      return saleComposition;
    }
    return 'package';
  }

  bool get isMixedPackageSale => compositionKind == 'mixed';

  bool get isPackageOnlySale => compositionKind == 'package';

  String get displayTitle {
    final base = isPackageSale
        ? (packageName ?? product)
        : (productBase?.trim().isNotEmpty == true ? productBase! : product);
    return formatProductWithVariant(
      productName: base,
      sizeLabel: sizeLabel,
      colorLabel: colorLabel,
      variantLabel: variantLabel,
    );
  }

  String get displayProductNameOnly => isPackageSale
      ? (packageName ?? product)
      : (productBase?.trim().isNotEmpty == true ? productBase! : product);

  bool get isFromMaintenance => maintenanceId != null;

  String get invoiceNumber {
    final invoice = invoiceNumberValue?.trim();
    if (invoice != null && invoice.isNotEmpty) return invoice;
    final serial = serialNumber?.trim();
    if (serial != null && serial.isNotEmpty) return serial;
    return 'SAL-${id.toString().padLeft(7, '0')}';
  }

  /// Total piece count (package lines sum sub-qty; else main + extras).
  int get piecesCount {
    if (isPackageSale) {
      final mainQty = int.tryParse(quantity) ?? 0;
      final extraQty = additionalProductLines.fold<int>(
        0,
        (sum, p) => sum + (int.tryParse(p.quantity) ?? 0),
      );
      return mainQty + extraQty;
    }
    final mainQty = int.tryParse(quantity) ?? 0;
    if (subProducts.isEmpty) return mainQty;
    final subTotal = subProducts.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p.quantity) ?? 0),
    );
    return subTotal > 0 ? mainQty + subTotal : mainQty;
  }

  bool get isCustomerBuyer =>
      buyerType == 'customer' || buyerType == 'customers';

  bool get isSellerBuyer => buyerType == 'seller' || buyerType == 'sellers';

  String get partnerName {
    final name = buyerName?.trim();
    if (name != null && name.isNotEmpty && name != '-') return name;
    final project = projectName?.trim();
    if (project != null && project.isNotEmpty) return project;
    return '—';
  }

  /// Lines shown in the invoice detail modal.
  List<InstantSaleLineItem> get lineItems {
    final lines = <InstantSaleLineItem>[];
    if (isPackageSale) {
      lines.add(InstantSaleLineItem(
        name: displayTitle,
        quantity: quantity,
        unitCost: cost,
        isPackageHeader: true,
      ));
    } else {
      lines.add(InstantSaleLineItem(
        name: formatProductWithVariant(
          productName: product.isNotEmpty ? product : displayProductNameOnly,
          sizeLabel: sizeLabel,
          colorLabel: colorLabel,
          variantLabel: variantLabel,
        ),
        quantity: quantity,
        unitCost: cost,
        sizeLabel: sizeLabel,
        colorLabel: colorLabel,
      ));
    }
    for (final sub in packageComponentLines) {
      lines.add(InstantSaleLineItem(
        name: sub.displayProductName,
        quantity: sub.quantity,
        unitCost: sub.cost,
        sizeLabel: sub.sizeLabel,
        colorLabel: sub.colorLabel,
      ));
    }
    for (final sub in additionalProductLines) {
      lines.add(InstantSaleLineItem(
        name: sub.displayProductName,
        quantity: sub.quantity,
        unitCost: sub.cost,
        isAdditionalProduct: true,
        sizeLabel: sub.sizeLabel,
        colorLabel: sub.colorLabel,
      ));
    }
    return lines;
  }

  String get displayBuyerLine {
    final name = buyerName?.trim();
    if (name != null && name.isNotEmpty && name != '-') {
      final type = buyerTypeLabelAr?.trim();
      if (type != null && type.isNotEmpty) {
        return '$type: $name';
      }
      return name;
    }
    final project = projectName?.trim();
    if (project != null && project.isNotEmpty) {
      return project;
    }
    return '';
  }

  factory InstantSalesModel.fromJson(Map<String, dynamic> json) {
    return InstantSalesModel(
      id: asInt(json['id']),
      invoiceNumberValue: asNullableString(json['invoice_number']),
      serialNumber: asNullableString(json['serial_number']),
      maintenanceId: json['maintenance_id'] == null
          ? null
          : int.tryParse('${json['maintenance_id']}'),
      maintenanceInvoiceNumber:
          asNullableString(json['maintenance_invoice_number']),
      saleKind: asString(json['sale_kind'], 'regular'),
      saleKindLabelAr: asNullableString(json['sale_kind_label_ar']),
      product: asString(json['product']),
      productBase: asNullableString(json['product_base']),
      cost: asString(json['cost'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      date: parseApiDateTime(json['date']),
      createdAt: json['created_at'] != null
          ? parseApiDateTime(json['created_at'])
          : null,
      notes: asString(json['notes']),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductsModel.fromJson(m),
      ),
      buyerType: asNullableString(json['buyer_type']),
      buyerTypeLabelAr: asNullableString(json['buyer_type_label_ar']),
      buyerId:
          json['buyer_id'] == null ? null : int.tryParse('${json['buyer_id']}'),
      buyerName: asNullableString(json['buyer_name']),
      buyerPhone: asNullableString(json['buyer_phone']),
      projectName: asNullableString(json['project_name']),
      status: asNullableString(json['status']),
      paymentBoxName: asNullableString(json['payment_box_name']),
      paymentBoxValue: asNullableString(json['payment_box_value']?.toString()),
      paidAmount: asString(
        json['paid_amount'],
        asString(json['payment_box_value'], '0'),
      ),
      remainingAmount: asString(json['remaining_amount'], '0'),
      isPackageSale: json['is_package_sale'] == true ||
          json['is_package_sale'] == 1 ||
          json['sale_type'] == 'package',
      offerPackageId: json['offer_package_id'] == null
          ? null
          : int.tryParse('${json['offer_package_id']}'),
      packageName: asNullableString(json['package_name']),
      saleType: asString(json['sale_type'], 'product'),
      saleComposition: asString(json['sale_composition'], 'product'),
      hasAdditionalProducts: json['has_additional_products'] == true ||
          json['has_additional_products'] == 1,
      createdBy: json['created_by'] == null
          ? null
          : int.tryParse('${json['created_by']}'),
      createdByName: asNullableString(json['created_by_name']),
      updatedBy: json['updated_by'] == null
          ? null
          : int.tryParse('${json['updated_by']}'),
      updatedByName: asNullableString(json['updated_by_name']),
      sizeLabel: parseVariantSizeLabel(json),
      colorLabel: parseVariantColorLabel(json),
      variantLabel: asNullableString(json['variant_label']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumberValue,
      'serial_number': serialNumber,
      'maintenance_id': maintenanceId,
      'maintenance_invoice_number': maintenanceInvoiceNumber,
      'sale_kind': saleKind,
      'sale_kind_label_ar': saleKindLabelAr,
      'product': product,
      'cost': cost,
      'total_cost': totalCost,
      'quantity': quantity,
      'date': date,
      'created_at': createdAt,
      'notes': notes,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
      'buyer_type': buyerType,
      'buyer_type_label_ar': buyerTypeLabelAr,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'project_name': projectName,
    };
  }
}

class InstantSaleLineItem {
  final String name;
  final String quantity;
  final String unitCost;
  final bool isPackageHeader;
  final bool isAdditionalProduct;
  final String? sizeLabel;
  final String? colorLabel;

  const InstantSaleLineItem({
    required this.name,
    required this.quantity,
    required this.unitCost,
    this.isPackageHeader = false,
    this.isAdditionalProduct = false,
    this.sizeLabel,
    this.colorLabel,
  });
}

class SubProductsModel {
  final int id;
  final String productName;
  final String? productNameBase;
  final String cost;
  final String quantity;
  final bool isPackageComponent;
  final bool isAdditionalProduct;
  final String? sizeLabel;
  final String? colorLabel;
  final String? variantLabel;

  const SubProductsModel({
    required this.id,
    required this.productName,
    this.productNameBase,
    required this.cost,
    required this.quantity,
    this.isPackageComponent = false,
    this.isAdditionalProduct = false,
    this.sizeLabel,
    this.colorLabel,
    this.variantLabel,
  });

  factory SubProductsModel.fromJson(Map<String, dynamic> json) {
    final cost = asString(json['cost'], '0');
    final lineCost = double.tryParse(cost) ?? 0;
    final fromApiAdditional = json['is_additional_product'] == true ||
        json['is_additional_product'] == 1;
    final isAdditional = fromApiAdditional || lineCost > 0;

    return SubProductsModel(
      id: asInt(json['id']),
      productName: asString(json['product_name']),
      productNameBase: asNullableString(json['product_name_base']),
      cost: cost,
      quantity: asString(json['quantity'], '0'),
      isPackageComponent: !isAdditional,
      isAdditionalProduct: isAdditional,
      sizeLabel: parseVariantSizeLabel(json),
      colorLabel: parseVariantColorLabel(json),
      variantLabel: asNullableString(json['variant_label']),
    );
  }

  String get displayProductName => formatProductWithVariant(
        productName: productNameBase?.trim().isNotEmpty == true
            ? productNameBase!
            : productName,
        sizeLabel: sizeLabel,
        colorLabel: colorLabel,
        variantLabel: variantLabel,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'cost': cost,
      'quantity': quantity,
      'is_package_component': isPackageComponent,
      'is_additional_product': isAdditionalProduct,
    };
  }
}

extension InstantSaleSubProductsX on InstantSalesModel {
  List<SubProductsModel> get packageComponentLines => isPackageSale
      ? subProducts.where((s) => !s.isAdditionalProduct).toList()
      : subProducts;

  List<SubProductsModel> get additionalProductLines => isPackageSale
      ? subProducts.where((s) => s.isAdditionalProduct).toList()
      : const [];
}
