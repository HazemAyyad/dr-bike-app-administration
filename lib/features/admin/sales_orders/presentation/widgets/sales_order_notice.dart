import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';

/// إشعار مركزي لشاشات الطلبيات — نفس أسلوب إضافة مهمة الموظف.
class SalesOrderNotice {
  SalesOrderNotice._();

  /// نفس مدة إشعار إضافة مهمة الموظف — يظهر في المنتصف ثم يختفي.
  static const Duration flashDuration = Duration(milliseconds: 500);

  static BuildContext? get _context {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx is Element && !ctx.mounted) return null;
    return ctx;
  }

  static void success(String message, {String title = 'success'}) {
    final ctx = _context;
    if (ctx == null) return;
    Helpers.showCustomDialogSuccess(
      context: ctx,
      title: title,
      message: message,
      autoCloseAfter: flashDuration,
    );
  }

  /// يُغلق لودر التقدّم أولاً ثم يعرض الإشعار (لا يُكدّس فوق الـ dialog).
  static void successDeferred(String message, {String title = 'success'}) {
    Future.microtask(() => success(message, title: title));
  }

  static void info(String message, {String title = 'info'}) {
    success(message, title: title);
  }

  static void infoDeferred(String message, {String title = 'info'}) {
    successDeferred(message, title: title);
  }

  static void error(String message, {String title = 'error'}) {
    final ctx = _context;
    if (ctx == null) return;
    Helpers.showCustomDialogError(
      context: ctx,
      title: title,
      message: _displayMessage(message),
    );
  }

  static void errorDeferred(String message, {String title = 'error'}) {
    Future.microtask(() => error(message, title: title));
  }

  static String _displayMessage(String raw) {
    final msg = raw.trim();
    if (msg.contains('SQLSTATE') || msg.contains('BIGINT UNSIGNED')) {
      return 'salesOrderActionFailedGeneric'.tr;
    }
    if (msg.contains('Array to string conversion')) {
      return 'shiplyHandoverFailedGeneric'.tr;
    }
    if (msg.length > 220) {
      return '${msg.substring(0, 217)}...';
    }
    return msg;
  }
}
