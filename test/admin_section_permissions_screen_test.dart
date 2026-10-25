import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/views/admin_section_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

class _PermissionsApi implements DioConsumer {
  bool canEdit = true;
  bool fullAccess = false;
  bool failSave = false;
  List<String> sections = ['sales'];
  Map<String, dynamic>? saved;
  String? savedPath;

  @override
  Future<Response> get(String path,
          {Options? options,
          Object? data,
          Map<String, dynamic>? queryParameters}) async =>
      Response(requestOptions: RequestOptions(path: path), data: {
        'status': 'success',
        'full_access': fullAccess,
        'can_edit': canEdit,
        'sections': sections,
        'available_sections': [
          {'key': 'sales', 'name': 'المبيعات'},
          {'key': 'stock', 'name': 'المخزون'},
        ],
      });

  @override
  Future<Response> put(String path,
      {dynamic data,
      Options? options,
      Map<String, dynamic>? queryParameters,
      bool isFormData = false}) async {
    saved = Map<String, dynamic>.from(data as Map);
    savedPath = path;
    if (failSave) throw StateError('offline');
    return Response(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'success'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _PermissionsApi api;

  setUp(() {
    Get.testMode = true;
    api = _PermissionsApi();
    Get.put<DioConsumer>(api);
  });
  tearDown(() => Get.reset());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const AdminSectionPermissionsScreen(
                        adminId: 7, adminName: 'أحمد'),
                  )),
                  child: const Text('open'),
                ),
              )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('selects and saves sections for the chosen admin',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('المخزون'));
    await tester.tap(find.text('حفظ الصلاحيات'));
    await tester.pumpAndSettle();
    expect(api.savedPath, 'admin/users/7/sections');
    expect(api.saved!['full_access'], isFalse);
    expect(api.saved!['sections'], unorderedEquals(['sales', 'stock']));
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports no sections and keeps selection after a failed save',
      (tester) async {
    api.failSave = true;
    await open(tester);
    await tester.tap(find.text('المبيعات'));
    await tester.tap(find.text('حفظ الصلاحيات'));
    await tester.pumpAndSettle();
    expect(api.saved!['sections'], isEmpty);
    expect(find.text('تعذر حفظ الصلاحيات. حاول مجددًا.'), findsOneWidget);
    expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full access can be changed to restricted access',
      (tester) async {
    api.fullAccess = true;
    api.sections = [];
    await open(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المخزون'));
    await tester.tap(find.text('حفظ الصلاحيات'));
    await tester.pumpAndSettle();
    expect(api.saved!['full_access'], isFalse);
    expect(api.saved!['sections'], ['stock']);
  });

  testWidgets('the current manager can view but cannot edit their own access',
      (tester) async {
    api.canEdit = false;
    await open(tester);
    expect(find.text('لا يمكنك تعديل صلاحيات حسابك الحالي.'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull);
    expect(api.saved, isNull);
  });
}
