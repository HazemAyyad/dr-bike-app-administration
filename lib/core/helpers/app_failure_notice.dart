import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AppFailureNotice {
  AppFailureNotice._();

  static const Duration defaultDuration = Duration(milliseconds: 3500);
  static const Duration detailedDuration = Duration(milliseconds: 6500);
  static OverlayEntry? _activeEntry;

  static Future<void> show({
    BuildContext? context,
    required String title,
    required String message,
    bool? detailed,
  }) {
    final OverlayState? overlay = context == null
        ? Get.key.currentState?.overlay
        : Overlay.maybeOf(context, rootOverlay: true);
    final OverlayState? resolvedOverlay =
        overlay ?? Get.key.currentState?.overlay;
    if (resolvedOverlay == null) return Future<void>.value();

    final bool showDetails = detailed ?? _needsDetails(message);
    final Duration duration = showDetails ? detailedDuration : defaultDuration;
    _removeActive();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FailureOverlay(
        title: title,
        message: message,
        detailed: showDetails,
        duration: duration,
        onDismiss: () {
          if (!identical(_activeEntry, entry)) return;
          _activeEntry = null;
          entry.remove();
        },
      ),
    );
    _activeEntry = entry;
    resolvedOverlay.insert(entry);
    return Future<void>.delayed(duration);
  }

  static Future<void> showBlocking({
    required BuildContext context,
    required String title,
    required String message,
    bool barrierDismissible = false,
    String? actionLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440.w),
              child: _FailureCard(
                title: title,
                message: message,
                detailed: true,
                actionLabel: actionLabel,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  static bool _needsDetails(String message) {
    final String text = message.trim();
    return text.length > 80 || text.contains('\n');
  }

  static void _removeActive() {
    final OverlayEntry? entry = _activeEntry;
    _activeEntry = null;
    entry?.remove();
  }
}

class _FailureOverlay extends StatefulWidget {
  const _FailureOverlay({
    required this.title,
    required this.message,
    required this.detailed,
    required this.duration,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final bool detailed;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_FailureOverlay> createState() => _FailureOverlayState();
}

class _FailureOverlayState extends State<_FailureOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _enterDuration = Duration(milliseconds: 170);
  static const Duration _exitDuration = Duration(milliseconds: 120);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;
  Timer? _dismissTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _enterDuration,
      reverseDuration: _exitDuration,
    );
    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = curve;
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.98, end: 1).animate(curve);
    _controller.forward();

    final int exitDelayMs = math.max(
      0,
      widget.duration.inMilliseconds - _exitDuration.inMilliseconds,
    );
    _dismissTimer = Timer(Duration(milliseconds: exitDelayMs), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted || _closing) return;
    _closing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double top = math.max(
      media.padding.top + 72.h,
      media.size.height * 0.19,
    );

    return Positioned(
      top: top,
      left: 16.w,
      right: 16.w,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440.w,
              maxHeight: media.size.height * 0.42,
            ),
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _offset,
                child: ScaleTransition(
                  scale: _scale,
                  child: _FailureCard(
                    title: widget.title,
                    message: widget.message,
                    detailed: widget.detailed,
                    duration: widget.duration,
                    onClose: _dismiss,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({
    required this.title,
    required this.message,
    required this.detailed,
    required this.onClose,
    this.duration,
    this.actionLabel,
  });

  final String title;
  final String message;
  final bool detailed;
  final VoidCallback onClose;
  final Duration? duration;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface =
        isDark ? const Color(0xFF202A38) : const Color(0xFFFFFDFD);
    final String safeTitle = title.trim().isEmpty ? 'error'.tr : title;
    final String safeMessage =
        message.trim().isEmpty ? 'حدث خطأ غير متوقع. حاول مرة أخرى.' : message;

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF633D43) : const Color(0xFFF1DADC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.15),
              blurRadius: 26.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 10.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _FailureLogo(isDark: isDark),
                        SizedBox(width: 11.w),
                        Expanded(
                          child: Text(
                            safeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFFF9AA3)
                                  : const Color(0xFFB42332),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'close'.tr,
                          onPressed: onClose,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 19.sp,
                            color: isDark
                                ? const Color(0xFF9DA6B4)
                                : const Color(0xFF747C89),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: detailed ? 9.h : 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF35282E)
                              : const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            safeMessage,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFE6C9CC)
                                  : const Color(0xFF6D4A4E),
                              fontSize: 12.sp,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (actionLabel != null) ...[
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        height: 42.h,
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC53240),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            actionLabel!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (duration != null)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1, end: 0),
                duration: duration!,
                builder: (_, value, __) => Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 2.h,
                      color: const Color(0xFFE5484D),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FailureLogo extends StatelessWidget {
  const _FailureLogo({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF44272D) : const Color(0xFFFFECEE),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.close_rounded,
        size: 23.sp,
        color: isDark ? const Color(0xFFFF9AA3) : const Color(0xFFC53240),
      ),
    );
  }
}
