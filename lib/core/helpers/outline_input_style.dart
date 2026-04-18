import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared outlined field look (radius 12, visible border, theme-aware).
class OutlineInputStyle {
  OutlineInputStyle._();

  static const double radius = 12;

  static EdgeInsetsGeometry contentPadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h);

  static Color _enabledBorderColor(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark
        ? Theme.of(context).colorScheme.outline
        : Colors.grey.shade300;
  }

  static InputDecoration merge(
    BuildContext context, {
    InputDecoration? base,
    String? labelText,
    String? hintText,
    TextStyle? hintStyle,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(radius.r);
    final enabledSide = BorderSide(color: _enabledBorderColor(context), width: 1);
    final focusedSide = BorderSide(color: cs.primary, width: 2);

    return (base ?? const InputDecoration()).copyWith(
      filled: true,
      fillColor: cs.surface,
      contentPadding: contentPadding(context),
      labelText: labelText,
      hintText: hintText,
      hintStyle: hintStyle ??
          TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16.sp,
          ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: r, borderSide: enabledSide),
      enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: enabledSide),
      disabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(
          color: _enabledBorderColor(context).withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(borderRadius: r, borderSide: focusedSide),
      errorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: cs.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
    );
  }
}
