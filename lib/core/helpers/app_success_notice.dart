import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AppSuccessNotice {
  AppSuccessNotice._();

  static const Duration defaultDuration = Duration(milliseconds: 2000);
  static OverlayEntry? _activeEntry;

  static Future<void> show({
    BuildContext? context,
    required String title,
    required String message,
    Duration duration = defaultDuration,
  }) {
    final OverlayState? overlay = context == null
        ? Get.key.currentState?.overlay
        : Overlay.maybeOf(context, rootOverlay: true);
    final OverlayState? resolvedOverlay =
        overlay ?? Get.key.currentState?.overlay;
    if (resolvedOverlay == null) {
      return Future<void>.value();
    }

    _removeActive();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppSuccessNoticeOverlay(
        title: title,
        message: message,
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

  static void _removeActive() {
    final OverlayEntry? entry = _activeEntry;
    _activeEntry = null;
    entry?.remove();
  }
}

class _AppSuccessNoticeOverlay extends StatefulWidget {
  const _AppSuccessNoticeOverlay({
    required this.title,
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AppSuccessNoticeOverlay> createState() =>
      _AppSuccessNoticeOverlayState();
}

class _AppSuccessNoticeOverlayState extends State<_AppSuccessNoticeOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _enterDuration = Duration(milliseconds: 140);
  static const Duration _exitDuration = Duration(milliseconds: 100);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;
  Timer? _dismissTimer;

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
      begin: const Offset(0, -0.16),
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
    if (!mounted) return;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double top = math.max(
      media.padding.top + 72.h,
      media.size.height * 0.19,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _opacity,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.14),
              ),
            ),
            Positioned(
              top: top,
              left: 16.w,
              right: 16.w,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 440.w),
                    child: FadeTransition(
                      opacity: _opacity,
                      child: SlideTransition(
                        position: _offset,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF202A38)
                                    : const Color(0xFFFDFEFD),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF355143)
                                      : const Color(0xFFDDEBE3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.34 : 0.14,
                                    ),
                                    blurRadius: 26.r,
                                    offset: Offset(0, 10.h),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      13.w,
                                      11.h,
                                      13.w,
                                      10.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40.w,
                                          height: 40.w,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF173B2B)
                                                : const Color(0xFFEDF9F2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 23.sp,
                                            color: isDark
                                                ? const Color(0xFF71D9A2)
                                                : const Color(0xFF178653),
                                          ),
                                        ),
                                        SizedBox(width: 11.w),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.title.trim().isEmpty
                                                    ? 'success'.tr
                                                    : widget.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? const Color(0xFF83E0AF)
                                                      : const Color(0xFF176D46),
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (widget.message
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                SizedBox(height: 3.h),
                                                Text(
                                                  widget.message,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFBDC5D1)
                                                        : const Color(
                                                            0xFF626C7C),
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 1, end: 0),
                                    duration: widget.duration,
                                    builder: (_, value, __) => Align(
                                      alignment: Alignment.centerRight,
                                      child: FractionallySizedBox(
                                        widthFactor: value,
                                        child: Container(
                                          height: 2.h,
                                          color: const Color(0xFF34C759),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
