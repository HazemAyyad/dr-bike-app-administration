import 'package:doctorbike/core/helpers/json_safe_parser.dart';

String formatProductWithVariant({
  required String productName,
  String? sizeLabel,
  String? colorLabel,
  String? variantLabel,
}) {
  final name = productName.trim().isEmpty ? '—' : productName.trim();
  if (productNameAlreadyShowsVariant(
    productName: name,
    sizeLabel: sizeLabel,
    colorLabel: colorLabel,
    variantLabel: variantLabel,
  )) {
    return name;
  }
  final fromApi = variantLabel?.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return '$name — $fromApi';
  }
  final size = sizeLabel?.trim();
  final color = colorLabel?.trim();
  if (size != null &&
      size.isNotEmpty &&
      color != null &&
      color.isNotEmpty) {
    return '$name — $size / $color';
  }
  if (size != null && size.isNotEmpty) {
    return '$name — $size';
  }
  if (color != null && color.isNotEmpty) {
    return '$name — $color';
  }
  return name;
}

bool productNameAlreadyShowsVariant({
  required String productName,
  String? sizeLabel,
  String? colorLabel,
  String? variantLabel,
}) {
  final name = productName.trim();
  if (name.isEmpty) return false;

  final variant = variantLabel?.trim();
  if (variant != null && variant.isNotEmpty) {
    if (name.contains(variant)) return true;
    if (name.contains(' — $variant')) return true;
  }

  final size = sizeLabel?.trim();
  final color = colorLabel?.trim();
  if (size != null &&
      size.isNotEmpty &&
      color != null &&
      color.isNotEmpty &&
      name.contains('$size / $color')) {
    return true;
  }

  return false;
}

String? parseVariantSizeLabel(Map<String, dynamic> json) {
  return asNullableString(json['size']) ??
      asNullableString(json['size_label']);
}

String? parseVariantColorLabel(Map<String, dynamic> json) {
  return asNullableString(json['color_ar']) ??
      asNullableString(json['color_label']);
}

bool hasProductVariant({
  String? sizeLabel,
  String? colorLabel,
  String? variantLabel,
}) {
  final variant = variantLabel?.trim();
  if (variant != null && variant.isNotEmpty) return true;
  return (sizeLabel?.trim().isNotEmpty ?? false) ||
      (colorLabel?.trim().isNotEmpty ?? false);
}

String variantDashOrValue(String? value) {
  final v = value?.trim();
  return v == null || v.isEmpty ? '—' : v;
}
