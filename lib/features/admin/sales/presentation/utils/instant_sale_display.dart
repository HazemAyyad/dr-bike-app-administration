import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/instant_sales_model.dart';

export '../../data/utils/sale_variant_display.dart';

/// Calendar-day key for grouping sales on the same date.
String instantSaleDateGroupKey(InstantSalesModel sale) {
  final local = (sale.createdAt ?? sale.date).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '${day.year}-$m-$d';
}

DateTime? parseInstantSaleDateGroupKey(String key) {
  try {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}

String formatInstantSalesDateHeader(String key, {required int invoiceCount}) {
  final dt = parseInstantSaleDateGroupKey(key);
  if (dt == null) return key;
  final locale = Get.locale?.toString() ?? 'ar';
  final dateLabel = DateFormat('EEEE، d MMMM yyyy', locale).format(dt);
  return '$dateLabel · $invoiceCount ${'instantSaleInvoicesCount'.tr}';
}

extension InstantSaleDisplay on InstantSalesModel {
  String get addedByDisplay {
    final name = createdByName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '—';
  }

  String get editedByDisplay {
    final name = updatedByName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'instantSaleNotEdited'.tr;
  }

  bool get hasEditor => updatedByName?.trim().isNotEmpty == true;

  String get partnerTypeDisplay {
    final ar = buyerTypeLabelAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    if (isCustomerBuyer) return 'customer'.tr;
    if (isSellerBuyer) return 'seller'.tr;
    if (projectName != null && projectName!.trim().isNotEmpty) {
      return 'project'.tr;
    }
    return '—';
  }
}
