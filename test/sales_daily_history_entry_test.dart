import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/boxes/data/models/get_shown_boxes_model.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_daily_history_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_daily_admin_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/views/sales_daily_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Almarai')
          ..addFont(
              rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf')))
        .load();
  });
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('daily history route registers sales actions on direct entry', () {
    SalesDailyHistoryBinding().dependencies();
    expect(Get.isRegistered<SalesController>(), isTrue);
    expect(Get.isPrepared<SalesController>(), isTrue);
  });

  for (final existingSales in [false, true]) {
    testWidgets(
        'closing requests load on entry, existing sales: $existingSales',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final previousUserType = userType;
      final previousPermissions = employeePermissionNames;
      userType = 'employee';
      employeePermissionNames = ['Sales'];
      addTearDown(() {
        userType = previousUserType;
        employeePermissionNames = previousPermissions;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sales = _DailySalesController();
      if (existingSales) {
        Get.put<SalesController>(sales);
        sales.pendingDailyClosingRequests.clear();
      } else {
        Get.lazyPut<SalesController>(() => sales);
      }
      Get.put<SalesDailyHistoryController>(_HistoryController());
      SalesDailyHistoryBinding().dependencies();

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          theme: ThemeData(fontFamily: 'Almarai'),
          home: const SalesDailyHistoryScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(sales.loads, existingSales ? 2 : 1);
      expect(find.text('طلبات إغلاق صندوق المبيعات (1)'), findsOneWidget);
      expect(find.text('موظف الاختبار'), findsOneWidget);
      expect(find.text('موافقة وإغلاق'), findsOneWidget);
      final review = _ReviewController();
      Get.put<SalesDailyAdminController>(review);
      await tester.ensureVisible(find.text('موافقة وإغلاق'));
      await tester.tap(find.text('موافقة وإغلاق'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('مراجعة طلب الإغلاق والترحيل'), findsOneWidget);
      expect(review.approvals, 0);
      Get.back();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _DailySalesController extends GetxController implements SalesController {
  int loads = 0;

  @override
  final dailySessionPayload = Rxn<DailySessionPayload>();
  @override
  final salesOrdersDailySessionPayload = Rxn<DailySessionPayload>();
  @override
  final pendingDailyClosingRequests = <DailyClosingRequestModel>[].obs;
  @override
  final pendingSalesCancellationRequests =
      <SalesCancellationRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDailySession();
  }

  @override
  Future<void> loadDailySession() async {
    loads++;
    pendingDailyClosingRequests.assignAll([
      const DailyClosingRequestModel(
        id: 42,
        status: 'pending',
        employeeName: 'موظف الاختبار',
        businessDate: '2026-10-24',
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HistoryController extends SalesDailyHistoryController {
  _HistoryController() : super(datasource: _UnusedDatasource());

  @override
  Future<void> loadAll() async {
    todayOverview.value = const DailyTodayOverviewModel(
      businessDate: '2026-10-25',
    );
  }
}

class _UnusedDatasource implements SalesDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewController extends GetxController
    implements SalesDailyAdminController {
  int approvals = 0;
  @override
  final isProcessing = false.obs;
  @override
  final shownBoxes = <ShownBoxesModel>[].obs;

  @override
  Future<void> loadAll() async {}

  @override
  Future<bool> approveClosing({
    required int requestId,
    required List<Map<String, dynamic>> transfers,
    bool showSuccess = true,
  }) async {
    approvals++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
