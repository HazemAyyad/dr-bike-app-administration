import 'package:get/get.dart';

import '../../../../../core/helpers/app_success_notice.dart';

class LedgerFlashMessageScreen {
  static Future<void> show(String message, {Duration? duration}) async {
    AppSuccessNotice.show(
      title: 'success'.tr,
      message: message,
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
