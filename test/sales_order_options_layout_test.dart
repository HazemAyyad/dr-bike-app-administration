import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/data/repositories/sales_orders_implement.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/controllers/sales_orders_controller.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_orders_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('order options fit and scroll at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final previousUserType = userType;
      userType = 'admin';
      Get.testMode = true;
      addTearDown(() {
        userType = previousUserType;
        Get.reset();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = _LayoutController();
      controller.orders.add(SalesOrderListItemModel(
        id: 42,
        customerName: 'زبون تجريبي',
        status: 'unconfirmed',
        total: 25,
        paymentType: 'cash',
      ));
      Get.put<SalesOrdersController>(controller);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: size,
        minTextAdapt: true,
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          home: const Scaffold(
            body: SingleChildScrollView(child: SalesOrdersTable()),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.drag(find.text('زبون تجريبي'), const Offset(220, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخيارات'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('فتح تفاصيل الطلبية').hitTestable(), findsOneWidget);
      final sheet = find.byType(BottomSheet);
      final scrollable =
          find.descendant(of: sheet, matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(
        find.text('حذف إجباري'),
        120,
        scrollable: scrollable,
      );
      expect(find.text('حذف إجباري').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('بقية الإجراءات تظهر داخل الطلبية حسب حالتها ومتطلباتها'),
        120,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _LayoutController extends SalesOrdersController {
  _LayoutController() : super(repository: _UnusedRepository());

  @override
  Future<void> loadOrders() async {}

  @override
  Future<void> loadLookups() async {}
}

class _UnusedRepository implements SalesOrdersRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
