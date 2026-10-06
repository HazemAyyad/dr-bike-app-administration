import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/helpers.dart';

class OnlineStoreFeedback {
  const OnlineStoreFeedback._();

  static String readinessLabel(String code) =>
      const {
        'missing_active_category': 'اختر تصنيف متجر نشطاً لهذا المنتج.',
        'missing_main_media': 'حدد صورة رئيسية ظاهرة للمنتج.',
        'missing_product': 'المنتج الأصلي غير موجود أو مؤرشف.',
        'missing_price': 'أضف سعر بيع صالحاً للمنتج الأصلي.',
        'unavailable_product': 'المنتج غير متاح للبيع حالياً.',
        'missing_name': 'أضف اسماً للمنتج.',
      }[code] ??
      code.replaceAll('_', ' ');

  static String message(Object error) {
    if (error is ServerException) {
      final details = _details(error.errorModel.data);
      if (details.isNotEmpty) return details;
      return _translate(error.errorModel.errorMessage);
    }
    return _translate(error.toString().replaceFirst('Exception: ', ''));
  }

  static void error(Object error,
      {String title = 'تعذر تنفيذ العملية', BuildContext? context}) {
    final target = context ?? Get.context;
    if (target == null) return;
    Helpers.showCustomDialogError(
      context: target,
      title: title,
      message: message(error),
    );
  }

  static void success(String message,
      {String title = 'تم بنجاح', BuildContext? context}) {
    final target = context ?? Get.context;
    if (target == null) return;
    Helpers.showCustomDialogSuccess(
      context: target,
      title: title,
      message: message,
    );
  }

  static String _details(dynamic data) {
    if (data is Map) {
      final messages = <String>[];
      for (final value in data.values) {
        if (value is List) {
          messages.addAll(value.map((item) => readinessLabel('$item')));
        } else if (value != null) {
          messages.add(readinessLabel('$value'));
        }
      }
      return messages.toSet().join('\n');
    }
    return '';
  }

  static String _translate(String message) {
    if (message.contains('not ready for this transition')) {
      return 'المنتج غير مكتمل بعد. عالج متطلبات النشر الظاهرة ثم حاول مجدداً.';
    }
    return message;
  }
}
