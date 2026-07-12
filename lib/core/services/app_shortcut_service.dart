import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../routes/app_routes.dart';
import 'languague_service.dart';
import 'final_classes.dart';
import 'initial_bindings.dart';

/// Home-screen quick actions (long-press app icon) and deferred deep navigation.
class AppShortcutService {
  AppShortcutService._();

  static final AppShortcutService instance = AppShortcutService._();

  static const String addSpecialTask = 'add_special_task';
  static const int specialTasksPermissionId = 6;

  static const QuickActions _quickActions = QuickActions();

  String? _pendingShortcut;
  bool _initialized = false;

  bool get canOpenAddSpecialTask =>
      userType == 'admin' ||
      employeePermissions.contains(specialTasksPermissionId);

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    try {
      debugPrint('[WidgetShortcutFlow] initialize route=${Get.currentRoute}');
      await _quickActions.initialize(_onShortcutSelected);
      await refreshShortcutItems();
      debugPrint(
          '[WidgetShortcutFlow] initialize done route=${Get.currentRoute}');
    } catch (e, st) {
      debugPrint('[AppShortcut] init failed: $e\n$st');
    }
  }

  Future<void> refreshShortcutItems() async {
    if (kIsWeb || !_initialized) return;

    final lang = _currentLangCode();
    final title = lang == 'ar' ? 'إضافة مهمة خاصة' : 'Add special task';

    try {
      await _quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
          type: addSpecialTask,
          localizedTitle: title,
          icon: 'ic_shortcut_add_task',
        ),
      ]);
    } catch (e, st) {
      debugPrint('[AppShortcut] setShortcutItems failed: $e\n$st');
    }
  }

  void _onShortcutSelected(String type) {
    debugPrint(
      '[WidgetShortcutFlow] quick action selected type=$type route=${Get.currentRoute}',
    );
    _pendingShortcut = type;
    if (_isAuthenticatedMainShell()) {
      scheduleConsumePending();
    }
  }

  void scheduleConsumePending() {
    debugPrint(
      '[WidgetShortcutFlow] schedule consume pending=$_pendingShortcut route=${Get.currentRoute}',
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      consumePendingShortcutIfAny();
    });
  }

  void triggerAddSpecialTaskFromExternal() {
    debugPrint(
      '[WidgetShortcutFlow] external trigger add_special_task route=${Get.currentRoute}',
    );
    _pendingShortcut = addSpecialTask;
    scheduleConsumePending();
  }

  Future<void> consumePendingShortcutIfAny() async {
    final type = _pendingShortcut;
    debugPrint(
      '[WidgetShortcutFlow] consume start pending=$type route=${Get.currentRoute} '
      'userType=$userType permissions=$employeePermissions',
    );
    if (type == null || type.isEmpty) {
      debugPrint('[WidgetShortcutFlow] consume ignored empty pending');
      return;
    }
    _pendingShortcut = null;

    if (type != addSpecialTask) {
      debugPrint('[WidgetShortcutFlow] consume ignored unknown type=$type');
      return;
    }

    if (!_isAuthenticatedMainShell()) {
      debugPrint(
        '[WidgetShortcutFlow] app not ready, keep pending type=$type route=${Get.currentRoute}',
      );
      _pendingShortcut = type;
      return;
    }

    if (!canOpenAddSpecialTask) {
      debugPrint('[WidgetShortcutFlow] permission denied for add_special_task');
      Get.snackbar(
        'error'.tr,
        'shortcutSpecialTaskNoPermission'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    debugPrint(
      '[WidgetShortcutFlow] after delay route=${Get.currentRoute} pending=$_pendingShortcut',
    );

    if (Get.currentRoute == AppRoutes.CREATETASKSCREEN) {
      debugPrint('[WidgetShortcutFlow] already on create task screen');
      return;
    }

    debugPrint('[WidgetShortcutFlow] opening create special task screen');
    await Get.toNamed(
      AppRoutes.CREATETASKSCREEN,
      arguments: const {
        'title': 'addNewPravateTask',
        'isEdit': false,
        'fromHomeWidget': true,
      },
    );
    debugPrint(
        '[WidgetShortcutFlow] create special task route completed route=${Get.currentRoute}');
  }

  bool _isAuthenticatedMainShell() {
    if (userType.isEmpty) {
      debugPrint('[WidgetShortcutFlow] not authenticated: empty userType');
      return false;
    }
    final route = Get.currentRoute;
    if (route.isEmpty ||
        route == '/' ||
        route.startsWith('/?') ||
        route.contains('homeWidget=true')) {
      debugPrint('[WidgetShortcutFlow] not ready: route=$route');
      return false;
    }
    const authBlocked = <String>{
      AppRoutes.SPLASHSCREEN,
      AppRoutes.LOGINSCREEN,
      AppRoutes.LOGINORSIGNUPSCREEN,
      AppRoutes.ONBOARDINGSCREEN,
      AppRoutes.NOINTERNETSCREEN,
    };
    final ready = !authBlocked.contains(route);
    if (!ready) {
      debugPrint('[WidgetShortcutFlow] blocked route=$route');
    }
    return ready;
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
