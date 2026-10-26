import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/admin_user_model.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/admin_users_usecase.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/controllers/add_admin_controller.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/controllers/employee_section_controller.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/views/add_edit_admin_screen.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/widgets/employee_sections_list/admin_list.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

const _admin = AdminUserModel(
  id: 7,
  name: 'أحمد',
  email: 'admin@example.com',
  isBlocked: false,
  isOnline: true,
  developmentRole: 'none',
  activeSessionsCount: 1,
  adminFcmDevicesCount: 1,
);

class _Admins implements ManageAdminUserUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Employees implements EmployeeSectionController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PermissionsApi implements DioConsumer {
  String? requestedPath;

  @override
  Future<Response> get(String path,
      {Options? options,
      Object? data,
      Map<String, dynamic>? queryParameters}) async {
    requestedPath = path;
    return Response(requestOptions: RequestOptions(path: path), data: {
      'status': 'success',
      'full_access': false,
      'can_edit': true,
      'sections': ['sales'],
      'available_sections': [
        {'key': 'sales', 'name': 'المبيعات'},
      ],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  Widget host({List<GetPage> pages = const []}) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => GetMaterialApp(
          getPages: pages,
          home: const Scaffold(body: AdminList(admin: _admin)),
        ),
      );

  testWidgets('admin actions and development roles render above their Material',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(AdminList));
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('دور تطوير التطبيق'));
    await tester.pumpAndSettle();
    expect(find.text('صاحب التطبيق'), findsOneWidget);
    expect(find.text('مبرمج'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'permission navigation retains the chosen admin after arguments change',
      (tester) async {
    final api = _PermissionsApi();
    Get.put<DioConsumer>(api);
    await tester.pumpWidget(host(pages: [
      GetPage(
        name: AppRoutes.ADDEDITADMINSCREEN,
        page: () => const AddEditAdminScreen(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => AddAdminController(
                manageAdminUserUsecase: _Admins(),
                sectionController: _Employees(),
              ));
        }),
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AdminList));
    await tester.pumpAndSettle();
    final controller = Get.find<AddAdminController>();
    expect(controller.editingAdmin?.id, 7);

    await tester.tap(find.text('صلاحيات الأقسام'));
    await tester.pumpAndSettle();
    expect(find.text('صلاحيات أحمد'), findsOneWidget);
    expect(api.requestedPath, 'admin/users/7/sections');
    expect(controller.editingAdmin?.id, 7);
    expect(controller.isEdit, isTrue);
    expect(tester.takeException(), isNull);

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('صلاحيات الأقسام'), findsOneWidget);
    expect(controller.nameController.text, _admin.name);
    expect(controller.editingAdmin?.id, 7);
    expect(tester.takeException(), isNull);

    Get.back<void>();
    await tester.pumpAndSettle();
    const nextAdmin = AdminUserModel(
      id: 8,
      name: 'علي',
      email: 'other@example.com',
      isBlocked: false,
      isOnline: false,
      developmentRole: 'none',
      activeSessionsCount: 0,
      adminFcmDevicesCount: 0,
    );
    Get.toNamed<void>(AppRoutes.ADDEDITADMINSCREEN,
        arguments: {'isEdit': true, 'admin': nextAdmin});
    await tester.pumpAndSettle();
    expect(Get.find<AddAdminController>().editingAdmin?.id, 8);
    expect(Get.find<AddAdminController>().nameController.text, nextAdmin.name);
    expect(tester.takeException(), isNull);
  });
}
