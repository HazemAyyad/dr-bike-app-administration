import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/reports/data/reports_api_service.dart';
import 'package:doctorbike/features/admin/reports/presentation/controllers/reports_controller.dart';
import 'package:doctorbike/features/admin/reports/presentation/views/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('groups reports, filters search and explains a report',
      (tester) async {
    final controller = _putController();
    await _pump(tester, const ReportsScreen());

    expect(controller.reportGroups, hasLength(4));
    expect(controller.reports, hasLength(16));
    expect(find.text('تقارير أساسية'), findsOneWidget);
    expect(find.text('تقرير المبيعات'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ميزان المراجعة');
    await tester.pump();

    expect(find.text('ميزان المراجعة'), findsNWidgets(2));
    expect(find.text('تقرير المبيعات'), findsNothing);
    expect(find.text('الدفاتر والقيود'), findsOneWidget);

    const description =
        'يعرض أرصدة الحسابات المدينة والدائنة للتأكد من توازن القيود.';
    await tester.tap(find.byTooltip(description));
    await tester.pumpAndSettle();

    expect(find.text('فهمت'), findsOneWidget);
    expect(find.text(description), findsNWidgets(2));
  });

  testWidgets('detail app bar keeps report actions under one menu',
      (tester) async {
    final controller = _putController();
    controller.selectedReport.value = 'sales';
    controller.hasLoadedCurrentReport = true;

    await _pump(tester, const ReportsDetailScreen());
    expect(find.byTooltip('خيارات التقرير'), findsOneWidget);

    await tester.tap(find.byTooltip('خيارات التقرير'));
    await tester.pumpAndSettle();

    expect(find.text('الفلاتر'), findsOneWidget);
    expect(find.text('تنزيل PDF'), findsOneWidget);
    expect(find.text('مشاركة PDF'), findsOneWidget);
    expect(find.text('طباعة'), findsOneWidget);
  });
}

ReportsController _putController() {
  final controller = ReportsController(
    service: ReportsApiService(api: _UnusedApiConsumer()),
  );
  return Get.put(controller);
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => GetMaterialApp(
        locale: const Locale('ar'),
        home: child,
      ),
    ),
  );
}

class _UnusedApiConsumer implements ApiConsumer {
  Never _unused() => throw StateError('Network is not expected in this test.');

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  }) async =>
      _unused();

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  }) async =>
      _unused();

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async =>
      _unused();

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Function(int, int)? onSendProgress,
  }) async =>
      _unused();

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async =>
      _unused();
}
