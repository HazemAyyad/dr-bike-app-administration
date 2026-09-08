import 'app_success_notice.dart';

void showSweetSuccessDialog({
  required String title,
  required String message,
  String? subtitle,
}) {
  AppSuccessNotice.show(
    title: title,
    message:
        subtitle == null || subtitle.isEmpty ? message : '$message - $subtitle',
  );
}
