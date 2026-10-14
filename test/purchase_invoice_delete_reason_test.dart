import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/buying/data/datasources/bills_datasource.dart';
import 'package:doctorbike/features/admin/buying/presentation/widgets/bills_widgets/bills_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('purchase deletion sends the invoice and reason only', () async {
    final api = _RecordingApi();
    await BillsDatasource(api: api).purgePurchaseInvoice(
      billId: '61',
      reason: 'فاتورة تجريبية',
    );
    expect(api.path, EndPoints.purchasePurge);
    expect(api.body, {'bill_id': '61', 'reason': 'فاتورة تجريبية'});
  });

  testWidgets('reason alone enables deletion and returns trimmed text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? result;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const PurchaseInvoiceDeleteDialog(billId: '61'),
                );
              },
              child: const Text('open'),
            );
          }),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('كلمة مرور حسابك'), findsNothing);
    final button = find.widgetWithText(FilledButton, 'حذف وعكس الآثار');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  فاتورة تجريبية  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result, 'فاتورة تجريبية');
    expect(tester.takeException(), isNull);
  });
}

class _RecordingApi implements ApiConsumer {
  String? path;
  Object? body;

  @override
  Future<dynamic> post(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters,
      bool isFormData = false,
      Function(int, int)? onSendProgress}) async {
    this.path = path;
    body = data;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'status': 'success', 'message': 'تم الحذف'},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
