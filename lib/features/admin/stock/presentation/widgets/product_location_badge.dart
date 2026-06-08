import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductLocationLabel {
  ProductLocationLabel._();

  /// "اسم القسم - رقم الرف - رقم المنتج" (only non-empty parts, joined by " - ").
  static String? withProductCode({
    String? sectionName,
    String? shelfNumber,
    String? productCode,
  }) {
    final parts = <String>[
      if ((sectionName?.trim() ?? '').isNotEmpty) sectionName!.trim(),
      if ((shelfNumber?.trim() ?? '').isNotEmpty) shelfNumber!.trim(),
      if ((productCode?.trim() ?? '').isNotEmpty) productCode!.trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' - ');
  }
}

class ProductLocationBadge extends StatelessWidget {
  const ProductLocationBadge({
    Key? key,
    this.sectionName,
    this.shelfNumber,
    this.productCode,
    this.dense = true,
  }) : super(key: key);

  final String? sectionName;
  final String? shelfNumber;
  final String? productCode;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = ProductLocationLabel.withProductCode(
      sectionName: sectionName,
      shelfNumber: shelfNumber,
      productCode: productCode,
    );
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5.w : 8.w,
        vertical: dense ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: dense ? 8.sp : 10.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
