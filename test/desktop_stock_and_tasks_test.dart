import 'dart:async';

import 'package:doctorbike/core/helpers/custom_tab_bar.dart';
import 'package:doctorbike/features/App_entr/on_boarding/widgets/login_or_sign_up.dart';
import 'package:doctorbike/features/auth/domain/usecases/login_usecase.dart';
import 'package:doctorbike/features/auth/presentation/login/controllers/login_controller.dart';
import 'package:doctorbike/features/auth/presentation/login/views/login_screen.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_model.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/repositories/special_tasks_repository.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/usecases/cancel_special_task_usecase.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/usecases/completed_special_tasks_usecase.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/usecases/special_task_details_usecase.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/usecases/special_tasks_usecase.dart';
import 'package:doctorbike/features/admin/special_tasks/domain/usecases/subs_pecial_task_completed_usecase.dart';
import 'package:doctorbike/features/admin/special_tasks/presentation/controllers/special_tasks_controller.dart';
import 'package:doctorbike/features/admin/special_tasks/presentation/controllers/special_tasks_service.dart';
import 'package:doctorbike/features/admin/special_tasks/presentation/views/special_tasks_screen.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/stock_product_grid_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  const windows = TargetPlatformVariant({TargetPlatform.windows});

  for (final scale in [1.0, 1.5]) {
    testWidgets('1080x1920 portrait sign-in at ${scale * 100}%',
        (tester) async {
      tester.view.devicePixelRatio = scale;
      tester.view.physicalSize = const Size(1080, 1920);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Get.put<LoginController>(_LoginController());

      await tester.pumpWidget(_app(const LoginOrSignUpScreen()));
      await tester.pumpAndSettle();
      final loginButton = find.text('login');
      final center = 540 / scale;
      expect(loginButton.hitTestable(), findsOneWidget);
      expect(tester.getCenter(loginButton).dx, closeTo(center, 1));

      await tester.pumpWidget(_app(const LoginScreen()));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      expect(tester.getSize(fields.first).width, 420);
      expect(tester.getCenter(fields.first).dx, closeTo(center, 1));
      expect(loginButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: windows);
  }

  testWidgets('desktop welcome opens a centered and scrollable sign-in form',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Get.put<LoginController>(_LoginController());
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(1600, 1000),
      fontSizeResolver: (size, _) => size.toDouble(),
      builder: (_, __) => GetMaterialApp(
        locale: const Locale('en'),
        home: const LoginOrSignUpScreen(),
        getPages: [
          GetPage(name: AppRoutes.LOGINSCREEN, page: () => const LoginScreen()),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    final loginButton = find.text('login');
    expect(tester.getCenter(loginButton).dx, closeTo(700, 1));
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    expect(tester.getSize(fields.first).width, 420);
    tester.view.physicalSize = const Size(340, 360);
    await tester.pumpAndSettle();
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    expect(loginButton.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windows);

  testWidgets('narrow desktop stock tabs can be dragged in RTL',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(450, 950);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final currentTab = 0.obs;
    final tabs = List.generate(9, (i) => 'تاب المخزون ${i + 1}');

    await tester.pumpWidget(_app(
      Material(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topCenter,
            child: AppTabs(
              tabs: tabs,
              currentTab: currentTab,
              changeTab: (i) => currentTab.value = i,
              height: 44,
              tabVerticalPadding: 7,
              tabHorizontalPadding: 14,
              desktopScrollbar: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable);
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(find.byType(Scrollbar), findsOneWidget);
    await tester.drag(
      scrollable,
      const Offset(230, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(StockProductGridLayout.columnsForContext(tester.element(scrollable)),
        2);

    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expect(StockProductGridLayout.columnsForContext(tester.element(scrollable)),
        5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: windows);

  for (final scale in [1.0, 1.5]) {
    testWidgets(
        'portrait special tasks preserve scroll during refresh at ${scale * 100}%',
        (tester) async {
      tester.view.devicePixelRatio = scale;
      tester.view.physicalSize = const Size(1080, 1920);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repository = _TasksRepository();
      final service = SpecialTasksService();
      addTearDown(() {
        service.weeklyTasks.clear();
        service.noDateTasks.clear();
        service.archivedTasks.clear();
      });
      final controller = Get.put(SpecialTasksController(
        specialTasksUsecase:
            SpecialTasksUsecase(specialTasksRepository: repository),
        specialTasksService: service,
        cancelSpecialTaskUsecase:
            CancelSpecialTaskUsecase(specialTasksRepository: repository),
        completedSpecialTasksUsecase:
            CompletedSpecialTasksUsecase(specialTasksRepository: repository),
        specialTaskDetailsUsecase:
            SpecialTaskDetailsUsecase(specialTasksRepository: repository),
        subsSpecialTaskCompletedUsecase:
            SubsSpecialTaskCompletedUsecase(specialTasksRepository: repository),
      ));

      await tester.pumpWidget(_app(const SpecialTasksScreen()));
      await tester.pumpAndSettle();
      expect(find.text('weeklyTasks'), findsOneWidget);
      expect(find.text('noDateTasks'), findsOneWidget);
      final list = find.byType(CustomScrollView);
      await tester.drag(list, const Offset(0, -350),
          kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      final offset = controller.scrollController.offset;
      expect(offset, greaterThan(0));

      repository.pending = Completer<void>();
      final refresh = find.byTooltip('refresh');
      await tester.tap(refresh);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.weeklyRequests, 2);
      expect(controller.scrollController.offset, offset);

      await tester.tap(refresh);
      await tester.pump();
      expect(repository.weeklyRequests, 2);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(controller.scrollController.offset, offset);

      controller.scrollController.jumpTo(0);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(list);
      await tester.dragFrom(
        Offset(bounds.right - 3, bounds.top + 30),
        const Offset(0, 180),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(controller.scrollController.offset, greaterThan(0));

      controller.scrollController.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(list, Offset(0, bounds.height * 0.3),
          kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(repository.weeklyRequests, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: windows);
  }
}

Widget _app(Widget child) => ScreenUtilInit(
      designSize: const Size(1600, 1000),
      fontSizeResolver: (size, _) => size.toDouble(),
      builder: (_, __) => GetMaterialApp(
        locale: const Locale('en'),
        home: child,
      ),
    );

class _TasksRepository extends Fake implements SpecialTasksRepository {
  int weeklyRequests = 0;
  Completer<void>? pending;

  @override
  Future<List<SpecialTaskModel>> specialTasks({required String page}) async {
    if (page != '0') return [];
    weeklyRequests++;
    await pending?.future;
    final today = DateTime.now();
    return List.generate(
      40,
      (i) => SpecialTaskModel(
        id: i + 1,
        name: 'Task ${i + 1}',
        startDate: today,
        endDate: today,
        isCanceled: false,
        status: 'pending',
      ),
    );
  }
}

class _LoginController extends LoginController {
  _LoginController() : super(login: _UnusedLogin());

  // The widget test does not load saved credentials or call biometric plugins.
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _UnusedLogin extends Fake implements Login {}
