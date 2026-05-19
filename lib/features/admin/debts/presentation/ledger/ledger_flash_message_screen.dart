import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'ledger_colors.dart';

/// Brief full-screen message (e.g. restore success), auto-closes after [duration].
class LedgerFlashMessageScreen extends StatefulWidget {
  final String message;
  final Duration duration;

  const LedgerFlashMessageScreen({
    Key? key,
    required this.message,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  static Future<void> show(String message, {Duration? duration}) async {
    await Get.to(
      () => LedgerFlashMessageScreen(
        message: message,
        duration: duration ?? const Duration(seconds: 1),
      ),
      fullscreenDialog: true,
    );
  }

  @override
  State<LedgerFlashMessageScreen> createState() =>
      _LedgerFlashMessageScreenState();
}

class _LedgerFlashMessageScreenState extends State<LedgerFlashMessageScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) Get.back();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: LedgerColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}
