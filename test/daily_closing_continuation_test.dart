import 'dart:async';

import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/boxes/data/models/get_shown_boxes_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_daily_admin_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/views/sales_daily_admin_screen.dart';
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

  for (final approved in [true, false]) {
    testWidgets('review waits for approval result: $approved', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = _ClosingController();
      var returned = false;
      bool? result;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          theme: ThemeData(fontFamily: 'Almarai'),
          home: Scaffold(
            body: Builder(builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await SalesDailyClosingRequestsList.showClosingSheet(
                    context,
                    controller,
                    const DailyClosingRequestModel(
                      id: 42,
                      status: 'pending',
                      employeeName: 'موظف الاختبار',
                    ),
                    continueAfterApproval: true,
                  );
                  returned = true;
                },
                child: const Text('review'),
              );
            }),
          ),
        ),
      ));
      await tester.tap(find.text('review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('موافقة وترحيل ومتابعة'));
      await tester.pumpAndSettle();

      expect(controller.approvalCalls, 1);
      expect(controller.approvedRequestId, 42);
      expect(returned, isFalse);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      controller.approval.complete(approved);
      await tester.pumpAndSettle();
      if (approved) {
        expect(returned, isTrue);
        expect(result, isTrue);
        expect(find.byType(BottomSheet), findsNothing);
      } else {
        expect(returned, isFalse);
        expect(find.byType(BottomSheet), findsOneWidget);
        Get.back();
        await tester.pumpAndSettle();
        expect(returned, isTrue);
        expect(result, isNull);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _ClosingController extends GetxController
    implements SalesDailyAdminController {
  final approval = Completer<bool>();
  var approvalCalls = 0;
  int? approvedRequestId;

  @override
  final isProcessing = false.obs;
  @override
  final shownBoxes = <ShownBoxesModel>[].obs;

  @override
  Future<bool> approveClosing({
    required int requestId,
    required List<Map<String, dynamic>> transfers,
    bool showSuccess = true,
  }) {
    approvalCalls++;
    approvedRequestId = requestId;
    return approval.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
