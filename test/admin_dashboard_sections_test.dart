import 'package:doctorbike/core/services/admin_section_permissions.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/repositories/admin_dashboard_repository.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/usecases/get_activity_summary_usecase.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/usecases/get_admin_logs_usecase.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/usecases/get_admin_ui_preferences_usecase.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/usecases/get_main_dashboard_data_usecase.dart';
import 'package:doctorbike/features/admin/admin_dashbord/domain/usecases/save_admin_ui_preferences_usecase.dart';
import 'package:doctorbike/features/admin/admin_dashbord/presentation/controllers/admin_dashboard_controller.dart';
import 'package:doctorbike/features/admin/admin_dashbord/presentation/views/admin_dashboard_screen.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/cancel_log_usecase.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/get_all_employee.dart';
import 'package:doctorbike/features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Employees implements GetAllEmployeeUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Logs implements GetAdminLogsUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Summary implements GetActivitySummaryUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cancel implements CancelLogUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Data implements GetMainDashboardDataUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Preferences implements GetAdminUiPreferencesUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Save implements SaveAdminUiPreferencesUsecase {
  DashboardUiPreferences value = const DashboardUiPreferences();

  @override
  Future<DashboardUiPreferences> call(
    List<String> hiddenButtonKeys, {
    required List<String> buttonOrderKeys,
    int? quickAccessCount,
    bool? showAttentionSection,
    List<String>? hiddenSectionKeys,
  }) async {
    value = DashboardUiPreferences(
      hiddenButtonKeys: hiddenButtonKeys,
      buttonOrderKeys: buttonOrderKeys,
      quickAccessCount: quickAccessCount ?? value.quickAccessCount,
      showAttentionSection: showAttentionSection ?? value.showAttentionSection,
      hiddenSectionKeys: hiddenSectionKeys ?? value.hiddenSectionKeys,
    );
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dashboard extends AdminDashboardController {
  _Dashboard(_Save save)
      : super(
          getAllEmployeeUsecase: _Employees(),
          getAdminLogsUsecase: _Logs(),
          getActivitySummaryUsecase: _Summary(),
          cancelLogUsecase: _Cancel(),
          getMainDashboardDataUsecase: _Data(),
          getAdminUiPreferencesUsecase: _Preferences(),
          saveAdminUiPreferencesUsecase: save,
        );

  @override
  // The test supplies state directly and deliberately skips network startup.
  // ignore: must_call_super
  void onInit() {}
  @override
  void onClose() {}
}

void main() {
  late _Dashboard controller;
  late _Save save;

  setUp(() {
    Get.testMode = true;
    syncSessionIdentity(type: 'admin', adminSections: null);
    save = _Save();
    controller = _Dashboard(save);
    controller.isDashboardPreparing.value = false;
    Get.put<AdminDashboardController>(controller);
    Get.put(AdminNotificationBadgeController());
  });
  tearDown(() {
    Get.reset();
    AdminSectionPermissions.sync('', null);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const GetMaterialApp(home: AdminDashboardScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'defaults show quick access and all sections without duplicate cards',
      (tester) async {
    await open(tester);
    expect(find.text('نظرة سريعة'), findsNothing);
    expect(find.text('الوصول السريع'), findsOneWidget);
    expect(find.text('كل الأقسام'), findsOneWidget);
    expect(find.text('sales'), findsOneWidget);
    expect(find.text('boxes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiding quick access restores its cards to all sections',
      (tester) async {
    await open(tester);
    await controller.setDashboardSectionVisible('quick_access', false);
    await tester.pumpAndSettle();
    expect(find.text('الوصول السريع'), findsNothing);
    expect(find.text('كل الأقسام'), findsOneWidget);
    expect(find.text('sales'), findsOneWidget);
    expect(save.value.hiddenSectionKeys, contains('quick_access'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('customization switches save overview and section visibility',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('customizeDashboard').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SwitchListTile, 'نظرة سريعة'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'الإجراءات التي تحتاج متابعة'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'نظرة سريعة'));
    await tester.pumpAndSettle();
    expect(save.value.hiddenSectionKeys, isNot(contains('overview')));
    expect(tester.takeException(), isNull);
  });
}
