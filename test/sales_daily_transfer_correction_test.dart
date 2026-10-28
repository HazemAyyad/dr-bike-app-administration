import 'dart:async';

import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/boxes/data/models/get_shown_boxes_model.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/sales_daily_transfer_correction_sheet.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/sales_daily_ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _request = DailyClosingHistoryModel(
  id: 206,
  status: 'approved',
  reviewedAt: '2026-10-28 05:16:01',
  reviewedBy: 'محمود',
  transfers: [
    {
      'currency': 'شيكل',
      'amount': 1896,
      'from_box_id': 86,
      'from_box_name': 'صندوق مبيعات محمود',
      'to_box_id': 64,
      'to_box_name': 'صندوق تست',
    }
  ],
);
const _target = ShownBoxesModel(
    boxId: 94,
    boxName: 'صندوق الإدارة',
    totalBalance: 100,
    isShown: true,
    currency: 'شيكل',
    type: '');

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

  test('correction capabilities default to denied on older server responses',
      () {
    final detail = DailySessionDetailModel.fromJson({
      'session': {'id': 199}
    });
    expect(detail.canCorrectTransfers, isFalse);
    expect(detail.canReturnToReview, isFalse);
  });

  testWidgets('history identifies destination, approval time and corrections',
      (tester) async {
    await _pump(tester, const SalesDailyClosingTile(request: _request));
    expect(find.textContaining('صندوق تست'), findsOneWidget);
    expect(find.textContaining('صندوق مبيعات محمود'), findsOneWidget);
    expect(
        find.textContaining('وقت الاعتماد: 2026-10-28 05:16'), findsOneWidget);
    expect(find.text('تصحيح صندوق الترحيل'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('redirect requires reason and explicit destination before saving',
      (tester) async {
    final datasource = _Datasource();
    bool? result;
    await _pumpSheet(tester, datasource,
        reverse: false, onResult: (value) => result = value);
    final picker = tester.widget<CustomDropdownFieldWithSearch>(
        find.byType(CustomDropdownFieldWithSearch));
    expect(picker.value, isNull);
    await tester.tap(find.text('تأكيد العملية'));
    await tester.pumpAndSettle();
    expect(datasource.calls, 0);
    expect(find.text('أدخل سبب التصحيح.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'تم اختيار وجهة خاطئة');
    await tester.tap(find.text('تأكيد العملية'));
    await tester.pumpAndSettle();
    expect(datasource.calls, 0);
    expect(find.text('اختر صندوق الوجهة لكل عملة.'), findsOneWidget);
    picker.onChanged(_target);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد العملية'));
    await tester.pumpAndSettle();
    expect(datasource.calls, 1);
    expect(datasource.action, 'redirect');
    expect(datasource.transfers, [
      {'currency': 'شيكل', 'to_box_id': 94}
    ]);
    expect(find.text('جارٍ الحفظ...'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    datasource.response.complete('تم');
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reversal errors keep review open and do not report success',
      (tester) async {
    final datasource = _Datasource();
    bool? result;
    await _pumpSheet(tester, datasource,
        reverse: true, onResult: (value) => result = value);
    expect(find.byType(CustomDropdownFieldWithSearch), findsNothing);
    await tester.enterText(find.byType(TextField), 'إعادة مراجعة المبلغ');
    await tester.tap(find.text('تأكيد العملية'));
    await tester.pumpAndSettle();
    expect(datasource.calls, 1);
    expect(datasource.action, 'return_to_review');
    expect(datasource.transfers, isEmpty);
    datasource.response
        .completeError(Exception('لا يمكن العكس بعد فتح جلسة أحدث'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
        find.textContaining('لا يمكن العكس بعد فتح جلسة أحدث'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancel does not change a transfer', (tester) async {
    final datasource = _Datasource();
    await _pumpSheet(tester, datasource, reverse: true, onResult: (_) {});
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(datasource.calls, 0);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => GetMaterialApp(
      translations: Translation(),
      locale: const Locale('ar'),
      theme: ThemeData(fontFamily: 'Almarai'),
      home: Scaffold(body: child),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _pumpSheet(WidgetTester tester, _Datasource datasource,
    {required bool reverse, required void Function(bool?) onResult}) async {
  await _pump(
      tester,
      Builder(
          builder: (context) => TextButton(
                onPressed: () async {
                  onResult(await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: false,
                    builder: (_) => SalesDailyTransferCorrectionSheet(
                      request: _request,
                      datasource: datasource,
                      returnToReview: reverse,
                      boxes: const [_target],
                    ),
                  ));
                },
                child: const Text('open'),
              )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _Datasource implements SalesDatasource {
  final response = Completer<String>();
  int calls = 0;
  String? action;
  List<Map<String, dynamic>> transfers = [];

  @override
  Future<String> correctDailyClosingTransfer({
    required int closingRequestId,
    required String action,
    required String reason,
    List<Map<String, dynamic>> transfers = const [],
  }) {
    expect(closingRequestId, 206);
    expect(reason, isNotEmpty);
    calls++;
    this.action = action;
    this.transfers = transfers;
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
