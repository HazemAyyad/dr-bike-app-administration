import 'package:flutter/material.dart';

class OnlineStoreAdminUi {
  OnlineStoreAdminUi._();
  static const pageBackground = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F5);
  static const border = Color(0xFFD7DBE0);
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF667085);
  static const accent = Color(0xFF6F42C1);
  static const danger = Color(0xFF9B1C1C);
  static const success = Color(0xFF176B45);

  static const double dialogCompactMaxWidth = 700;
  static const double dialogMaxWidth = 820;
  static const double dialogWideMaxWidth = 900;

  static double dialogWidth(BuildContext context,
      {double max = dialogMaxWidth}) {
    final viewport = MediaQuery.sizeOf(context).width;
    return (viewport - 48).clamp(280.0, max).toDouble();
  }

  static ButtonStyle get actionButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        backgroundColor: surface,
        side: const BorderSide(color: accent),
      );
}

class OnlineStoreDialogBody extends StatelessWidget {
  const OnlineStoreDialogBody({
    Key? key,
    required this.child,
    this.maxWidth = OnlineStoreAdminUi.dialogMaxWidth,
    this.maxHeightFactor = .78,
  }) : super(key: key);

  final Widget child;
  final double maxWidth;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: OnlineStoreAdminUi.dialogWidth(context, max: maxWidth),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
          ),
          child: SingleChildScrollView(child: child),
        ),
      );
}
