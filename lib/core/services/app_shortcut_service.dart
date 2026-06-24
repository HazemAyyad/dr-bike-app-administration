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
      await _quickActions.initialize(_onShortcutSelected);
      await refreshShortcutItems();
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
    _pendingShortcut = type;
    if (_isAuthenticatedMainShell()) {
      scheduleConsumePending();
    }
  }

  void scheduleConsumePending() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      consumePendingShortcutIfAny();
    });
  }

  void triggerAddSpecialTaskFromExternal() {
    _pendingShortcut = addSpecialTask;
    scheduleConsumePending();
  }

  Future<void> consumePendingShortcutIfAny() async {
    final type = _pendingShortcut;
    if (type == null || type.isEmpty) return;
    _pendingShortcut = null;

    if (type != addSpecialTask) return;

    if (!canOpenAddSpecialTask) {
      Get.snackbar(
        'error'.tr,
        'shortcutSpecialTaskNoPermission'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_isAuthenticatedMainShell()) {
      _pendingShortcut = type;
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (Get.currentRoute == AppRoutes.CREATETASKSCREEN) return;

    await Get.toNamed(
      AppRoutes.CREATETASKSCREEN,
      arguments: const {
        'title': 'addNewPravateTask',
        'isEdit': false,
      },
    );
  }

  bool _isAuthenticatedMainShell() {
    if (userType.isEmpty) return false;
    final route = Get.currentRoute;
    const authBlocked = <String>{
      AppRoutes.SPLASHSCREEN,
      AppRoutes.LOGINSCREEN,
      AppRoutes.LOGINORSIGNUPSCREEN,
      AppRoutes.ONBOARDINGSCREEN,
      AppRoutes.NOINTERNETSCREEN,
    };
    return !authBlocked.contains(route);
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
