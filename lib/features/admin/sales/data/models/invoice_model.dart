import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:get/get.dart';

import '../utils/sale_variant_display.dart';

class InvoiceModel {
  final int id;
  final String product;
  final String? productBase;
  final String productImage;
  final String cost;
  final String quantity;
  final String totalCost;
  final String discount;
  final List<SubProductModel> subProducts;

  final String invoiceNumber;
  final String invoiceDate;
  final String saleKind;
  final String? saleKindLabelAr;
  final String? traderName;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? paymentMethod;
  final String? paymentBoxName;
  final String? paymentBoxValue;
  final String? status;
  final String? saleStatus;
  final String? notes;
  final List<InvoiceAdditionalNote> additionalNotes;
  final String additionalNotesTotal;
  final String subtotal;
  final String tax;
  final String paidAmount;
  final String remainingAmount;
  final String? projectName;

  final String buyerType;
  final String buyerTypeLabelAr;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final int? buyerId;
  final bool isPackageSale;
  final String? packageName;
  final String saleType;
  final String? sizeLabel;
  final String? colorLabel;
  final String? variantLabel;
  final String? sizeColorId;
  final String? sizeId;
  final String? productId;
  final String? productCode;
  final int? offerPackageId;
  final String? projectId;
  final String? lineType;
  final String? paymentBoxId;
  final int? sellerId;
  final int? salesOrderId;
  final String? salesOrderSerial;
  final int? maintenanceId;
  final String? maintenanceInvoiceNumber;

  InvoiceModel({
    required this.id,
    required this.product,
    this.productBase,
    required this.productImage,
    required this.cost,
    required this.quantity,
    required this.totalCost,
    required this.discount,
    required this.subProducts,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.saleKind = 'regular',
    this.saleKindLabelAr,
    this.traderName,
    this.customerName,
    this.phone,
    this.address,
    this.paymentMethod,
    this.paymentBoxName,
    this.paymentBoxValue,
    this.status,
    this.saleStatus,
    this.notes,
    this.additionalNotes = const [],
    this.additionalNotesTotal = '0',
    required this.subtotal,
    required this.tax,
    required this.paidAmount,
    required this.remainingAmount,
    this.projectName,
    required this.buyerType,
    required this.buyerTypeLabelAr,
    required this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    this.buyerId,
    this.isPackageSale = false,
    this.packageName,
    this.saleType = 'product',
    this.sizeLabel,
    this.colorLabel,
    this.variantLabel,
    this.sizeColorId,
    this.sizeId,
    this.productId,
    this.productCode,
    this.offerPackageId,
    this.projectId,
    this.lineType,
    this.paymentBoxId,
    this.sellerId,
    this.salesOrderId,
    this.salesOrderSerial,
    this.maintenanceId,
    this.maintenanceInvoiceNumber,
  });

  bool get isAdjustmentSale => saleKind == 'adjustment';

  String get displaySaleKindLabel => saleKindLabelAr?.trim().isNotEmpty == true
      ? saleKindLabelAr!.trim()
      : (isAdjustmentSale ? 'adjustmentSale'.tr : 'instantSale'.tr);

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final buyerRaw = json['buyer'];
    final buyer = buyerRaw is Map<String, dynamic>
        ? buyerRaw
        : buyerRaw is Map
            ? Map<String, dynamic>.from(buyerRaw)
            : null;

    final legacyTrader = asNullableString(json['trader_name']);
    final legacyCustomer = asNullableString(json['customer_name']);
    final legacyPhone = asNullableString(json['phone']);
    final legacyAddress = asNullableString(json['address']);
    final legacyProject = asNullableString(json['project_name']);

    var buyerType = asString(buyer?['type'], '');
    var buyerTypeLabelAr = asString(buyer?['type_label_ar'], '');
    var buyerName = asString(buyer?['name'], '');
    var buyerPhone = asNullableString(buyer?['phone']);
    var buyerAddress = asNullableString(buyer?['address']);
    final buyerIdRaw = buyer?['id'];
    final buyerId = buyerIdRaw == null
        ? null
        : (buyerIdRaw is int ? buyerIdRaw : int.tryParse('$buyerIdRaw'));

    if (buyer == null) {
      if (legacyTrader != null && legacyTrader.trim().isNotEmpty) {
        buyerType = 'trader';
        buyerTypeLabelAr = 'تاجر';
        buyerName = legacyTrader.trim();
      } else if (legacyCustomer != null && legacyCustomer.trim().isNotEmpty) {
        buyerType = 'customer';
        buyerTypeLabelAr = 'زبون';
        buyerName = legacyCustomer.trim();
      } else if (legacyProject != null && legacyProject.trim().isNotEmpty) {
        buyerType = 'trader';
        buyerTypeLabelAr = 'تاجر';
        buyerName = legacyProject.trim();
      } else {
        buyerType = 'unknown';
        buyerTypeLabelAr = 'غير محدد';
        buyerName = '-';
      }
      buyerPhone ??= legacyPhone;
      buyerAddress ??= legacyAddress;
    }

    if (buyerName.trim().isEmpty) {
      buyerName = '-';
    }
    if (buyerTypeLabelAr.trim().isEmpty) {
      buyerTypeLabelAr = buyerType == 'trader'
          ? 'تاجر'
          : buyerType == 'customer'
              ? 'زبون'
              : 'غير محدد';
    }

    return InvoiceModel(
      id: asInt(json['id']),
      product: asString(json['product']),
      productBase: asNullableString(json['product_base']),
      productImage: asString(json['product_image']),
      cost: asString(json['cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      discount: asString(json['discount'], '0'),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductModel.fromJson(m),
      ),
      invoiceNumber: asString(json['invoice_number'], asString(json['id'])),
      invoiceDate: asString(json['invoice_date']),
      saleKind: asString(json['sale_kind'], 'regular'),
      saleKindLabelAr: asNullableString(json['sale_kind_label_ar']),
      traderName: legacyTrader,
      customerName: legacyCustomer,
      phone: buyerPhone ?? legacyPhone,
      address: buyerAddress ?? legacyAddress,
      paymentMethod: asNullableString(json['payment_method']),
      paymentBoxName: asNullableString(json['payment_box_name']),
      paymentBoxValue: asNullableString(json['payment_box_value']?.toString()),
      status: asNullableString(json['status']),
      saleStatus: asNullableString(json['sale_status']),
      notes: asNullableString(json['notes']),
      additionalNotes: mapList(
        json['additional_notes'],
        (Map<String, dynamic> m) => InvoiceAdditionalNote.fromJson(m),
      ),
      additionalNotesTotal: asString(json['additional_notes_total'], '0'),
      subtotal: asString(json['subtotal'], asString(json['total_cost'], '0')),
      tax: asString(json['tax'], '0'),
      paidAmount: asString(
        json['paid_amount'],
        asString(json['payment_box_value'], '0'),
      ),
      remainingAmount: asString(json['remaining_amount'], '0'),
      projectName: legacyProject,
      buyerType: buyerType.isEmpty ? 'unknown' : buyerType,
      buyerTypeLabelAr: buyerTypeLabelAr,
      buyerName: buyerName,
      buyerPhone: buyerPhone ?? legacyPhone,
      buyerAddress: buyerAddress ?? legacyAddress,
      buyerId: buyerId,
      isPackageSale: json['is_package_sale'] == true ||
          json['is_package_sale'] == 1 ||
          json['sale_type'] == 'package',
      packageName: asNullableString(json['package_name']),
      saleType: asString(json['sale_type'], 'product'),
      sizeLabel: parseVariantSizeLabel(json),
      colorLabel: parseVariantColorLabel(json),
      variantLabel: asNullableString(json['variant_label']),
      sizeColorId: asNullableString(json['size_color_id']),
      sizeId: asNullableString(json['size_id']),
      productId: asNullableString(json['product_id']?.toString()),
      productCode: asNullableString(json['product_code']?.toString()),
      offerPackageId: json['offer_package_id'] == null
          ? null
          : (json['offer_package_id'] is int
              ? json['offer_package_id'] as int
              : int.tryParse('${json['offer_package_id']}')),
      projectId: asNullableString(json['project_id']?.toString()),
      lineType: asNullableString(json['type']),
      paymentBoxId: asNullableString(json['payment_box_id']?.toString()),
      sellerId: json['seller_id'] == null
          ? null
          : (json['seller_id'] is int
              ? json['seller_id'] as int
              : int.tryParse('${json['seller_id']}')),
      salesOrderId: json['sales_order_id'] == null
          ? null
          : (json['sales_order_id'] is int
              ? json['sales_order_id'] as int
              : int.tryParse('${json['sales_order_id']}')),
      salesOrderSerial: asNullableString(json['sales_order_serial']),
      maintenanceId: json['maintenance_id'] == null
          ? null
          : (json['maintenance_id'] is int
              ? json['maintenance_id'] as int
              : int.tryParse('${json['maintenance_id']}')),
      maintenanceInvoiceNumber:
          asNullableString(json['maintenance_invoice_number']),
    );
  }

  String get displayProductTitle {
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

  String get displayTraderName =>
      buyerName.trim().isNotEmpty && buyerName != '-'
          ? buyerName
          : (traderName?.trim().isNotEmpty == true
                      ? traderName
                      : customerName?.trim().isNotEmpty == true
                          ? customerName
                          : projectName)
                  ?.trim() ??
              '-';

  String get displayPaymentBox {
    final name = paymentBoxName?.trim();
    if (name == null || name.isEmpty) {
      return '-';
    }
    final value = paymentBoxValue?.trim();
    if (value != null && value.isNotEmpty) {
      return '$name ($value)';
    }
    return name;
  }

  String get displaySaleStatus {
    final raw = (status ?? saleStatus ?? '').trim().toLowerCase();
    if (raw == 'cancelled') {
      return 'ملغى';
    }
    if (raw == 'active' || raw == 'normal') {
      return 'فعال';
    }
    return saleStatus?.trim().isNotEmpty == true ? saleStatus!.trim() : '-';
  }

  String get displayBuyerTypeLabel {
    if (buyerTypeLabelAr.trim().isNotEmpty && buyerTypeLabelAr != 'غير محدد') {
      return buyerTypeLabelAr;
    }
    switch (buyerType) {
      case 'trader':
        return 'تاجر';
      case 'customer':
        return 'زبون';
      default:
        return 'غير محدد';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_image': productImage,
      'cost': cost,
      'quantity': quantity,
      'total_cost': totalCost,
      'discount': discount,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'trader_name': traderName,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'payment_method': paymentMethod,
      'sale_status': saleStatus,
      'notes': notes,
      'additional_notes': additionalNotes.map((e) => e.toJson()).toList(),
      'additional_notes_total': additionalNotesTotal,
      'subtotal': subtotal,
      'tax': tax,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'project_name': projectName,
      'buyer': {
        'type': buyerType,
        'type_label_ar': buyerTypeLabelAr,
        'name': buyerName,
        'phone': buyerPhone,
        'address': buyerAddress,
        'id': buyerId,
      },
      'maintenance_id': maintenanceId,
      'maintenance_invoice_number': maintenanceInvoiceNumber,
      'product_code': productCode,
    };
  }
}

class InvoiceAdditionalNote {
  final String text;
  final String amount;

  const InvoiceAdditionalNote({
    required this.text,
    required this.amount,
  });

  factory InvoiceAdditionalNote.fromJson(Map<String, dynamic> json) {
    return InvoiceAdditionalNote(
      text: asString(json['text']),
      amount: asString(json['amount'], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'amount': amount,
    };
  }
}

class SubProductModel {
  final int id;
  final String productName;
  final String? productNameBase;
  final String productImage;
  final String cost;
  final String quantity;
  final String subtotal;
  final bool isPackageComponent;
  final bool isAdditionalProduct;
  final String? sizeLabel;
  final String? colorLabel;
  final String? variantLabel;
  final String? productId;
  final String? productCode;
  final String? sizeColorId;
  final String? sizeId;
  final String? lineType;
  final String? projectId;

  SubProductModel({
    required this.id,
    required this.productName,
    this.productNameBase,
    required this.productImage,
    required this.cost,
    required this.quantity,
    required this.subtotal,
    this.isPackageComponent = false,
    this.isAdditionalProduct = false,
    this.sizeLabel,
    this.colorLabel,
    this.variantLabel,
    this.productId,
    this.productCode,
    this.sizeColorId,
    this.sizeId,
    this.lineType,
    this.projectId,
  });

  factory SubProductModel.fromJson(Map<String, dynamic> json) {
    final cost = asString(json['cost'], '0');
    final qty = asString(json['quantity'], '0');
    final parsedSubtotal = asString(json['subtotal'], '');
    final lineSubtotal = parsedSubtotal.isNotEmpty
        ? parsedSubtotal
        : ((double.tryParse(cost) ?? 0) * (double.tryParse(qty) ?? 0))
            .toStringAsFixed(2);
    final lineCost = double.tryParse(cost) ?? 0;
    final fromApiAdditional = json['is_additional_product'] == true ||
        json['is_additional_product'] == 1;
    // سعر > 0 = منتج إضافي مع الباكيج (حتى لو API أرسل is_package_component للكل)
    final isAdditional = fromApiAdditional || lineCost > 0;
    final isComponent = !isAdditional;

    return SubProductModel(
      id: asInt(json['id']),
      productName: asString(json['product_name'], '-'),
      productNameBase: asNullableString(json['product_name_base']),
      productImage: asString(json['product_image'], 'no image'),
      cost: cost,
      quantity: qty,
      subtotal: lineSubtotal,
      isPackageComponent: isComponent,
      isAdditionalProduct: isAdditional,
      sizeLabel: parseVariantSizeLabel(json),
      colorLabel: parseVariantColorLabel(json),
      variantLabel: asNullableString(json['variant_label']),
      productId: asNullableString(json['product_id']?.toString()),
      productCode: asNullableString(json['product_code']?.toString()),
      sizeColorId: asNullableString(json['size_color_id']?.toString()),
      sizeId: asNullableString(json['size_id']?.toString()),
      lineType: asNullableString(json['type']),
      projectId: asNullableString(json['project_id']?.toString()),
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
      'product_image': productImage,
      'product_code': productCode,
      'cost': cost,
      'quantity': quantity,
      'subtotal': subtotal,
      'is_package_component': isPackageComponent,
      'is_additional_product': isAdditionalProduct,
    };
  }
}

extension InvoiceSubProductsX on InvoiceModel {
  List<SubProductModel> get packageComponentLines => isPackageSale
      ? subProducts.where((s) => !s.isAdditionalProduct).toList()
      : subProducts;

  List<SubProductModel> get additionalProductLines => isPackageSale
      ? subProducts.where((s) => s.isAdditionalProduct).toList()
      : const [];
}
