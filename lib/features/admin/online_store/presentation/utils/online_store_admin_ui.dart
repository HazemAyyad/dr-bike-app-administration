import 'package:flutter/material.dart';

class OnlineStoreAdminUi {
  OnlineStoreAdminUi._();
  static const pageBackground = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F5);
  static const modalSurface = Color(0xFFF7F8FA);
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

class OnlineStoreDialog extends StatelessWidget {
  const OnlineStoreDialog({
    Key? key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.icon,
  }) : super(key: key);

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: OnlineStoreAdminUi.modalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: OnlineStoreAdminUi.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        title: Row(children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OnlineStoreAdminUi.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OnlineStoreAdminUi.border),
              ),
              child: Icon(icon, color: OnlineStoreAdminUi.accent, size: 21),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: OnlineStoreAdminUi.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              child: title,
            ),
          ),
        ]),
        content: DefaultTextStyle.merge(
          style: const TextStyle(color: OnlineStoreAdminUi.textPrimary),
          child: content,
        ),
        actions: actions,
      );
}

Future<T?> showOnlineStoreBottomSheet<T>(
  BuildContext context, {
  required Widget child,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnlineStoreAdminUi.modalSurface,
      barrierColor: Colors.black38,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: child,
        ),
      ),
    );

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
