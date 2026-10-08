import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/presentation/utils/online_store_admin_ui.dart';
import 'package:doctorbike/features/admin/online_store/presentation/utils/online_store_feedback.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_categories_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_product_picker_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_categories_controller.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  test('readiness codes are shown as actionable Arabic messages', () {
    expect(OnlineStoreFeedback.readinessLabel('missing_active_category'),
        'اختر تصنيف متجر نشطاً لهذا المنتج.');
    expect(OnlineStoreFeedback.readinessLabel('missing_main_media'),
        'حدد صورة رئيسية ظاهرة للمنتج.');
  });
  test('product candidate parses inventory search response fields', () {
    final product = OnlineStoreProductCandidate.fromJson({
      'id': 17,
      'nameAr': 'دراجة',
      'nameEng': 'Bike',
      'product_code': 'BK-17',
      'stock': '4',
      'normail_price': 1200,
      'viewImages': [
        {'imageUrl': 'products/bike.jpg'}
      ],
    });

    expect(product.id, 17);
    expect(product.displayName, 'دراجة');
    expect(product.nameEn, 'Bike');
    expect(product.code, 'BK-17');
    expect(product.stock, 4);
    expect(product.retailPrice, 1200);
    expect(product.imageUrl, 'products/bike.jpg');
  });

  test('category edit payload preserves its existing image path', () {
    final payload = onlineStoreCategoryPayload(
      nameAr: ' قطع ',
      nameEn: ' Parts ',
      parentId: 3,
      isActive: true,
      showOnHome: false,
      imagePath: 'public/OnlineStore/Content/category.jpg',
    );

    expect(payload['image_path'], 'public/OnlineStore/Content/category.jpg');
    expect(payload['name_translations'], {'ar': 'قطع', 'en': 'Parts'});
    expect(payload.containsKey('sort_order'), isFalse);
  });

  test('already listed products cannot create duplicate listings', () {
    expect(canCreateOnlineStoreListing(17, {12, 17}), isFalse);
    expect(canCreateOnlineStoreListing(18, {12, 17}), isTrue);
  });

  testWidgets('dialog width is responsive and capped', (tester) async {
    double? narrow;
    double? wide;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 700)),
        child: Builder(builder: (context) {
          narrow = OnlineStoreAdminUi.dialogWidth(context);
          return const SizedBox();
        }),
      ),
    ));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1600, 900)),
        child: Builder(builder: (context) {
          wide = OnlineStoreAdminUi.dialogWidth(context);
          return const SizedBox();
        }),
      ),
    ));

    expect(narrow, 312);
    expect(wide, OnlineStoreAdminUi.dialogMaxWidth);
  });

  testWidgets('editing a category keeps text controllers alive while closing',
      (tester) async {
    Get.testMode = true;
    userType = 'admin';
    final repository = FakeOnlineStoreRepository();
    final categories = {
      'data': [
        {
          'id': 4,
          'name_translations': {'ar': 'دراجات كهربائية', 'en': 'E-bikes'},
          'is_active': true,
          'show_on_home': true,
          'sort_order': 0,
        }
      ],
    };
    repository.responses['GET ${EndPoints.onlineStoreCategories}'] = categories;
    repository.responses['PATCH ${EndPoints.onlineStoreCategories}/4'] = {
      'data': categories['data']!.first,
    };
    Get.put(OnlineStoreCategoriesController(repository));
    addTearDown(Get.reset);

    await tester.pumpWidget(const GetMaterialApp(
      locale: Locale('ar'),
      home: OnlineStoreCategoriesScreen(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دراجات كهربائية'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل التصنيف'), findsOneWidget);

    await tester.tap(find.text('حفظ').last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.calls,
        contains('PATCH ${EndPoints.onlineStoreCategories}/4'));
  });
}
