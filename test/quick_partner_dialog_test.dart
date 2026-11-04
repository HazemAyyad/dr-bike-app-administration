import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/widgets/quick_partner_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, _Api api,
      void Function(QuickPartnerResult?) onResult) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async => onResult(
                        await showDialog<QuickPartnerResult>(
                            context: context,
                            builder: (_) => QuickPartnerDialog(
                                isCustomer: true, api: api))),
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('name is required and cancellation sends no requests',
      (tester) async {
    final api = _Api();
    await open(tester, api, (_) {});
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل الاسم'), findsOneWidget);
    expect(api.posts, isEmpty);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(api.posts, isEmpty);
  });

  testWidgets(
      'creates and returns a retail customer without an address request',
      (tester) async {
    final api = _Api();
    QuickPartnerResult? result;
    await open(tester, api, (value) => result = value);
    await tester.enterText(find.byType(TextFormField).at(0), 'زبون جديد');
    await tester.enterText(find.byType(TextFormField).at(1), '0599123456');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(api.posts, hasLength(1));
    expect(api.posts.single['path'], EndPoints.createPerson);
    expect(api.posts.single['data'], containsPair('type', 'retail'));
    expect(result!.partner.id, 42);
    expect(result!.partner.phone, '+972 599123456');
    expect(result!.address, isNull);
  });

  testWidgets('customer category can be changed to wholesale', (tester) async {
    final api = _Api();
    await open(tester, api, (_) {});
    await tester.enterText(find.byType(TextFormField).first, 'زبون جملة');
    await tester.tap(find.text('مفرق').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('جملة').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(api.posts.single['data'], containsPair('type', 'wholesale'));
  });

  testWidgets('address retry preserves person and saves every address field',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _Api()..failAddress = true;
    QuickPartnerResult? result;
    await open(tester, api, (value) => result = value);
    await tester.enterText(find.byType(TextFormField).at(0), 'زبون جديد');
    await tester.tap(find.text('إضافة عنوان توصيل — اختياري'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byWidgetPredicate((widget) => widget is DropdownSearch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المنطقة — المدينة').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'المنزل');
    await tester.enterText(fields.at(3), 'شارع المدرسة');
    await tester.enterText(fields.at(4), '0599123456');
    await tester.enterText(fields.at(5), 'الطابق الثاني');
    await tester.tap(find.byType(SwitchListTile));
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('address failed'), findsOneWidget);
    api.failAddress = false;
    await tester.tap(find.text('حفظ العنوان'));
    await tester.pumpAndSettle();
    expect(api.posts.where((row) => row['path'] == EndPoints.createPerson),
        hasLength(1));
    final address = api.posts.last['data'] as Map;
    expect(address, containsPair('label', 'المنزل'));
    expect(address, containsPair('shiply_city_id', 1));
    expect(address, containsPair('shiply_village_id', 2));
    expect(address, containsPair('street_address', 'شارع المدرسة'));
    expect(address, containsPair('phone', '+972 599123456'));
    expect(address, containsPair('delivery_notes', 'الطابق الثاني'));
    expect(address, containsPair('is_default', true));
    expect(result!.address!.id, 7);
  });
}

class _Api extends Fake implements ApiConsumer {
  final List<Map<String, dynamic>> posts = [];
  bool failAddress = false;
  @override
  Future<dynamic> get(String path,
          {Object? data,
          Options? options,
          Map<String, dynamic>? queryParameters}) async =>
      Response(requestOptions: RequestOptions(path: path), data: {
        'cities': [
          {
            'id': 1,
            'name': 'المدينة',
            'villages': [
              {'id': 2, 'name': 'المنطقة', 'is_closed': false},
              {'id': 3, 'name': 'مغلقة', 'is_closed': true}
            ]
          }
        ]
      });

  @override
  Future<dynamic> post(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters,
      bool isFormData = false,
      Function(int, int)? onSendProgress}) async {
    posts.add({'path': path, 'data': data});
    return Response(
        requestOptions: RequestOptions(path: path),
        data: path == EndPoints.createPerson
            ? {'status': 'success', 'customer_id': 42}
            : failAddress
                ? {'status': 'error', 'message': 'address failed'}
                : {
                    'status': 'success',
                    'data': {'id': 7, ...data as Map}
                  });
  }
}
