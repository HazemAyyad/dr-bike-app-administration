import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_dashboard_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_listings_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_dashboard_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_listings_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_network_image.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('store products use three compact columns on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    userType = 'admin';
    final repository = FakeOnlineStoreRepository();
    repository.responses['listings'] = {
      'data': List.generate(
        4,
        (index) => {
          'id': index + 1,
          'product_id': index + 10,
          'status': 'published',
          'readiness_state': 'complete',
          'display': {'name': 'منتج ${index + 1}'},
          'base_prices': {'retail': 100 + index},
          'availability': {'available_qty': 5},
          'view_count': index == 0 ? 27 : index,
        },
      ),
    };
    Get.put(OnlineStoreListingsController(repository));

    await tester.pumpWidget(
      const GetMaterialApp(home: OnlineStoreListingsScreen()),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.mainAxisExtent, 218);
    expect(find.text('منتج 1'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date range fields stack instead of squeezing on phones',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final from = TextEditingController(text: '2026-10-01');
    final to = TextEditingController(text: '2026-10-31');
    addTearDown(from.dispose);
    addTearDown(to.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: OnlineStoreDateRangeFields(
            fromController: from,
            toController: to,
          ),
        ),
      ),
    ));

    final fields = find.byType(OnlineStoreDateTimeField);
    expect(fields, findsNWidgets(2));
    expect(tester.getTopLeft(fields.at(1)).dy,
        greaterThan(tester.getBottomLeft(fields.at(0)).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('management tools switch between list and icon grid',
      (tester) async {
    userType = 'admin';
    Get.put(OnlineStoreDashboardController(FakeOnlineStoreRepository()));

    await tester.pumpWidget(
      const GetMaterialApp(home: OnlineStoreDashboardScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsNothing);
    await tester.tap(find.byTooltip('عرض شبكة'));
    await tester.pump();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('المنتجات المعروضة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('online store image detection supports svg URLs with query strings', () {
    expect(
      isOnlineStoreSvgPath(
          'https://example.test/categories/electric-bike.SVG?v=3'),
      isTrue,
    );
    expect(
        isOnlineStoreSvgPath('images/categories/electric-bike.png'), isFalse);
  });

  test('store dates are rendered in a clear Arabic format', () {
    expect(
      onlineStoreFriendlyDate('2026-10-08 15:05'),
      '8 أكتوبر 2026، 3:05 م',
    );
  });
}
