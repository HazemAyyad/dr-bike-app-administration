import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import 'app_shortcut_service.dart';
import 'final_classes.dart';
import 'languague_service.dart';

/// Home screen widget (Android/iOS) for quick "add special task" access.
class AppHomeWidgetService {
  AppHomeWidgetService._();

  static final AppHomeWidgetService instance = AppHomeWidgetService._();

  static const appGroupId = 'group.com.nofal.doctorbike';
  static const androidWidgetName = 'AddSpecialTaskWidget';
  static const iosWidgetName = 'AddSpecialTaskWidget';
  static const widgetLaunchUri =
      'doctorbike://add_special_task?homeWidget=true';

  static const _titleKey = 'special_task_widget_title';
  static const _subtitleKey = 'special_task_widget_subtitle';

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    try {
      debugPrint('[HomeWidgetFlow] initialize start route=${Get.currentRoute}');
      await HomeWidget.setAppGroupId(appGroupId);
      await syncPresentation();

      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      debugPrint(
          '[HomeWidgetFlow] initialUri=$initialUri route=${Get.currentRoute}');
      _onWidgetUri(initialUri);

      HomeWidget.widgetClicked.listen(_onWidgetUri);
      debugPrint('[HomeWidgetFlow] initialize done route=${Get.currentRoute}');
    } catch (e, st) {
      debugPrint('[AppHomeWidget] init failed: $e\n$st');
    }
  }

  Future<void> syncPresentation() async {
    if (kIsWeb) return;

    final lang = _currentLangCode();
    final title = lang == 'ar' ? 'إضافة مهمة خاصة' : 'Add special task';
    final subtitle = lang == 'ar' ? 'اضغط لفتح التطبيق' : 'Tap to open the app';

    try {
      await HomeWidget.saveWidgetData<String>(_titleKey, title);
      await HomeWidget.saveWidgetData<String>(_subtitleKey, subtitle);
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iosWidgetName,
      );
    } catch (e, st) {
      debugPrint('[AppHomeWidget] sync failed: $e\n$st');
    }
  }

  void _onWidgetUri(Uri? uri) {
    debugPrint('[HomeWidgetFlow] widget uri=$uri route=${Get.currentRoute}');
    if (uri == null || !_isAddSpecialTaskUri(uri)) {
      debugPrint('[HomeWidgetFlow] ignored uri=$uri');
      return;
    }
    debugPrint('[HomeWidgetFlow] accepted add_special_task uri');
    AppShortcutService.instance.triggerAddSpecialTaskFromExternal();
  }

  bool _isAddSpecialTaskUri(Uri uri) {
    if (uri.queryParameters['homeWidget'] != 'true') return false;
    final host = uri.host;
    final path = uri.path;
    return host == 'add_special_task' ||
        path.contains('add_special_task') ||
        uri.toString().contains('add_special_task');
  }

  String _currentLangCode() {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return Get.find<LanguageController>().getLang();
      }
    } catch (_) {}
    final cached = FinalClasses.getStorage.read('lang');
    if (cached != null && cached.toString().isNotEmpty) {
      return cached.toString();
    }
    return 'ar';
  }
}
