import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/utils/app_colors.dart';

/// أزرار + / − موحّدة لبطاقة المنتج والسلة.
class InstantSaleQtyStepper extends StatelessWidget {
  const InstantSaleQtyStepper({
    Key? key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.onQuantityTap,
    this.canDecrement = true,
    this.canIncrement = true,
    this.compact = false,
  }) : super(key: key);

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onQuantityTap;
  final bool canDecrement;
  final bool canIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final btn = compact ? 22.w : 28.w;
    final icon = compact ? 13.sp : 16.sp;
    final qtyFont = compact ? 10.sp : 13.sp;
    final gap = compact ? 2.w : 6.w;
    final qtyWidth = compact ? 34.w : 40.w;

    final qtyWidget = onQuantityTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onQuantityTap,
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                width: qtyWidth,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: qtyFont,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        AppColors.primaryColor.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          )
        : SizedBox(
            width: qtyWidth,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: qtyFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepBtn(
          size: btn,
          icon: Icons.remove,
          iconSize: icon,
          enabled: canDecrement,
          onTap: onDecrement,
        ),
        SizedBox(width: gap),
        qtyWidget,
        SizedBox(width: gap),
        _StepBtn(
          size: btn,
          icon: Icons.add,
          iconSize: icon,
          enabled: canIncrement,
          onTap: onIncrement,
        ),
      ],
    );

    if (!compact) return row;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: row,
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.enabled,
    this.onTap,
  });

  final double size;
  final IconData icon;
  final double iconSize;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.primaryColor.withValues(alpha: 0.1)
          : Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
        side: BorderSide(
          color: enabled
              ? AppColors.primaryColor.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6.r),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: enabled ? AppColors.primaryColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
