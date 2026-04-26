import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Color productTagBackgroundColor(String colorHex) {
  var h = colorHex.trim();
  if (h.startsWith('#')) {
    h = h.substring(1);
  }
  if (h.length == 6) {
    h = 'FF$h';
  }
  try {
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return const Color(0xFF128C7E);
  }
}

class ProductTagChip extends StatelessWidget {
  const ProductTagChip({
    Key? key,
    required this.name,
    required this.colorHex,
    this.dense = false,
  }) : super(key: key);

  final String name;
  final String colorHex;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = productTagBackgroundColor(colorHex);
    final luminance = bg.computeLuminance();
    final fg = luminance > 0.55 ? Colors.black87 : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6.w : 10.w,
        vertical: dense ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: dense ? 9.sp : 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
