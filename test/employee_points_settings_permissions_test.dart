import 'dart:io';

import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/views/employee_points_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (_) async => Directory.systemTemp.path,
    );
    await GetStorage.init();
    ThemeService.isDark.value = false;
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
    userType = 'employee';
    employeePermissions = [];
    employeePermissionNames = [];
  });

  tearDown(() {
    userType = '';
    employeePermissions = [];
    employeePermissionNames = [];
    Get.reset();
  });

  testWidgets('points manager sees point-management settings', (tester) async {
    employeePermissions = [employeesPointsManagePermissionId];

    await _pumpSettings(tester);

    expect(find.text('قواعد النقاط التلقائية'), findsOneWidget);
    expect(find.text('pointCategoriesSetting'), findsOneWidget);
    expect(find.text('pointsReportTitle'), findsOneWidget);
    expect(find.text('rewardRulesSetting'), findsNothing);
    expect(find.text('subtaskBonusDefaultSetting'), findsNothing);
  });

  testWidgets('reward-rules permission alone cannot open points settings',
      (tester) async {
    employeePermissionNames = [employeesRewardsRulesManagePermissionName];

    await _pumpSettings(tester);

    expect(
      find.text('لا تملك صلاحية الوصول إلى إعدادات النقاط'),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('points manager with reward permission sees reward setting',
      (tester) async {
    employeePermissions = [employeesPointsManagePermissionId];
    employeePermissionNames = [employeesRewardsRulesManagePermissionName];

    await _pumpSettings(tester);

    expect(find.text('rewardRulesSetting'), findsOneWidget);
  });

  testWidgets('employee without management permissions is denied',
      (tester) async {
    employeePermissions = [employeesPointsViewPermissionId];

    await _pumpSettings(tester);

    expect(
      find.text('لا تملك صلاحية الوصول إلى إعدادات النقاط'),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('admin sees every setting', (tester) async {
    userType = 'admin';

    await _pumpSettings(tester);

    expect(find.text('قواعد النقاط التلقائية'), findsOneWidget);
    expect(find.text('pointCategoriesSetting'), findsOneWidget);
    expect(find.text('rewardRulesSetting'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('pointsReportTitle'), findsOneWidget);
    expect(find.text('subtaskBonusDefaultSetting'), findsOneWidget);
  });
}

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => const GetMaterialApp(
        locale: Locale('ar'),
        home: EmployeePointsSettingsScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1));
}
