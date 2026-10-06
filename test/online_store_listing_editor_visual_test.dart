import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_listings_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_media_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_listing_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('listing editor matches the approved RTL visual direction',
      (tester) async {
    final fonts = FontLoader('Almarai')
      ..addFont(rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf'));
    await fonts.load();
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    userType = 'admin';
    final repository = FakeOnlineStoreRepository();
    repository.responses['GET online-store/listings/7/media'] = {
      'data': {
        'items': [
          {
            'id': 1,
            'source_type': 'normal_image',
            'source_id': 101,
            'resolved_path': '',
            'is_main': true,
            'is_visible': true,
            'sort_order': 0,
          },
          {
            'id': 2,
            'source_type': 'normal_image',
            'source_id': 102,
            'resolved_path': '',
            'is_main': false,
            'is_visible': true,
            'sort_order': 1,
          },
        ],
      },
    };
    repository.responses['GET ${EndPoints.onlineStoreCategories}'] = {
      'data': [
        {
          'id': 4,
          'name_translations': {'ar': 'زيوت المحركات'},
          'is_active': true,
        }
      ],
    };
    repository.responses['GET ${EndPoints.onlineStoreCategories}/4'] = {
      'data': {
        'memberships': [
          {'online_store_listing_id': 7}
        ]
      },
    };

    Get.put(OnlineStoreListingsController(repository));
    Get.put(OnlineStoreMediaController(repository));
    final listing = OnlineStoreListing.fromJson({
      'id': 7,
      'product_id': 88,
      'status': 'draft',
      'readiness_state': 'complete',
      'readiness_issues': <dynamic>[],
      'name_translations': {'ar': 'زيت محرك Motul 10W40'},
      'description_translations': {
        'ar': 'زيت محرك شبه اصطناعي عالي الأداء مناسب للدراجات النارية.'
      },
      'product': {
        'id': 88,
        'code': 'P-1024',
        'name_translations': {'ar': 'زيت محرك Motul 10W40'},
        'description_translations': {
          'ar': 'زيت محرك شبه اصطناعي عالي الأداء مناسب للدراجات النارية.'
        },
      },
      'online_stock_limit': 10,
      'availability': {
        'physical_stock': 25,
        'reserved_qty': 3,
        'inventory_available_qty': 22,
        'available_qty': 10,
      },
      'is_featured': true,
      'is_new': true,
      'show_on_home': false,
    });

    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
      theme: ThemeData(fontFamily: 'Almarai'),
      home: const Scaffold(),
    ));
    Get.to(() => const OnlineStoreListingEditorScreen(), arguments: listing);
    await tester.pumpAndSettle();

    await expectLater(find.byType(Scaffold),
        matchesGoldenFile('goldens/online_store_listing_editor_ar.png'));
  });
}
