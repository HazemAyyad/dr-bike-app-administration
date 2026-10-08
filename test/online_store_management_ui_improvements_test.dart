import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_listings_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_listings_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('store products use two columns on a narrow phone',
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
    expect(delegate.crossAxisCount, 2);
    expect(find.text('منتج 1'), findsOneWidget);
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
}
