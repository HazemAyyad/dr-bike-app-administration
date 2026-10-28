import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/boxes/data/models/get_shown_boxes_model.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_daily_admin_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/views/sales_daily_close_screen.dart';
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

  for (final amount in [0.0, 1896.0]) {
    testWidgets('closing requires review and explicit transfer target: $amount',
        (tester) async {
      final fixture = await _openClosing(tester, amount: amount);
      await tester.ensureVisible(find.text('مراجعة واعتماد الإغلاق'));
      await tester.tap(find.text('مراجعة واعتماد الإغلاق'));
      await tester.pumpAndSettle();

      expect(fixture.sales.requests, 1);
      expect(fixture.admin.approvals, 0);
      expect(find.text('مراجعة طلب الإغلاق والترحيل'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      // Dismissing review must leave the request pending and reusable.
      Get.back();
      await tester.pumpAndSettle();
      expect(fixture.admin.approvals, 0);
      expect(find.text('مراجعة واعتماد الإغلاق'), findsOneWidget);
      await tester.tap(find.text('مراجعة واعتماد الإغلاق'));
      await tester.pumpAndSettle();
      expect(fixture.sales.requests, 1);

      final confirm = find.text('تأكيد الإغلاق والترحيل');
      if (amount > 0) {
        final picker = tester.widget<CustomDropdownFieldWithSearch>(
          find.byType(CustomDropdownFieldWithSearch),
        );
        expect(picker.value, isNull);
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(fixture.admin.approvals, 0);
        expect(find.byType(BottomSheet), findsOneWidget);
        picker.onChanged(fixture.admin.shownBoxes.single);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(fixture.admin.approvals, 1);
      expect(
          fixture.admin.transfers,
          amount == 0
              ? isEmpty
              : [
                  {'currency': 'شيكل', 'to_box_id': 64}
                ]);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('open closing'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('existing pending request opens review without resubmission',
      (tester) async {
    final fixture = await _openClosing(tester, amount: 182, pending: true);
    await tester.tap(find.text('مراجعة واعتماد الإغلاق'));
    await tester.pumpAndSettle();
    expect(fixture.sales.requests, 0);
    expect(fixture.admin.approvals, 0);
    expect(find.byType(BottomSheet), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('مراجعة واعتماد الإغلاق'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('employee submits request without approving it', (tester) async {
    final fixture = await _openClosing(tester, amount: 182, canReview: false);
    final submit = find.text('salesDailySubmitClosing'.tr);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(fixture.sales.requests, 1);
    expect(fixture.admin.approvals, 0);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Fixture {
  const _Fixture(this.sales, this.admin);
  final _Sales sales;
  final _Admin admin;
}

Future<_Fixture> _openClosing(
  WidgetTester tester, {
  required double amount,
  bool pending = false,
  bool canReview = true,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final datasource = _Datasource(amount, canReview, pending);
  final sales = _Sales(datasource);
  final admin = _Admin(datasource);
  Get.put<SalesDatasource>(datasource);
  Get.put<SalesController>(sales);
  Get.put<SalesDailyAdminController>(admin);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => GetMaterialApp(
      translations: Translation(),
      locale: const Locale('ar'),
      theme: ThemeData(fontFamily: 'Almarai'),
      home: Scaffold(
        body: TextButton(
          onPressed: () => Get.to(() => const SalesDailyCloseScreen()),
          child: const Text('open closing'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open closing'));
  await tester.pumpAndSettle();
  return _Fixture(sales, admin);
}

class _Datasource implements SalesDatasource {
  _Datasource(this.amount, this.canReview, this.pending);
  final double amount;
  final bool canReview;
  bool pending;

  DailySessionPayload get payload => DailySessionPayload(
        session: DailySessionInfo(
          id: 199,
          businessDate: '2026-10-28',
          status: pending ? 'closing_requested' : 'open',
          employeeName: 'موظف الاختبار',
          canRequestClosing: !pending,
        ),
        canFinalizeClosing: canReview,
        pendingClosingRequestId: pending ? 206 : null,
        currencies: [
          DailyCurrencyRow(
            currency: 'شيكل',
            dailyBoxId: 86,
            dailyBoxName: 'صندوق المبيعات',
            systemBalance: amount,
          )
        ],
      );

  DailyClosingRequestModel get request => DailyClosingRequestModel(
        id: 206,
        status: 'pending',
        employeeName: 'موظف الاختبار',
        cashCounts: [
          DailyCashCountRow(
            currency: 'شيكل',
            dailyBoxId: 86,
            physicalCount: amount,
            systemBalance: amount,
            amountToTransfer: amount,
          )
        ],
      );

  @override
  Future<DailySessionPayload> getDailySessionClosePayload(int sessionId) async {
    expect(sessionId, 199);
    return payload;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sales extends GetxController implements SalesController {
  _Sales(this.datasource)
      : dailySessionPayload = Rxn<DailySessionPayload>(datasource.payload);
  final _Datasource datasource;
  int requests = 0;
  @override
  final Rxn<DailySessionPayload> dailySessionPayload;
  @override
  final isDailySessionLoading = false.obs;

  @override
  Future<String> submitDailyClosing({
    required List<Map<String, dynamic>> cashCounts,
    List<Map<String, dynamic>> salesOrdersCashCounts = const [],
    String? lateCloseReason,
    int? sessionId,
    List<Map<String, dynamic>>? transfers,
    String? reviewNotes,
  }) async {
    expect(transfers, isNull);
    expect(sessionId, 199);
    requests++;
    datasource.pending = true;
    return 'تم إرسال طلب الإغلاق';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin extends GetxController implements SalesDailyAdminController {
  _Admin(this.datasource);
  @override
  final _Datasource datasource;
  int approvals = 0;
  List<Map<String, dynamic>>? transfers;
  @override
  final isProcessing = false.obs;
  @override
  final shownBoxes = [
    const ShownBoxesModel(
      boxId: 64,
      boxName: 'صندوق تست',
      currency: 'شيكل',
      totalBalance: 0,
      isShown: true,
      type: '',
    )
  ].obs;
  @override
  final closingRequests = <DailyClosingRequestModel>[].obs;

  @override
  Future<void> loadAll() async {
    closingRequests.assignAll([datasource.request]);
  }

  @override
  Future<bool> approveClosing({
    required int requestId,
    required List<Map<String, dynamic>> transfers,
    bool showSuccess = true,
  }) async {
    expect(requestId, 206);
    approvals++;
    this.transfers = transfers;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
