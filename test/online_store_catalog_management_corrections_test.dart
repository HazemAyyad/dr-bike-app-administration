import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/presentation/utils/online_store_admin_ui.dart';
import 'package:doctorbike/features/admin/online_store/presentation/utils/online_store_feedback.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_categories_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/views/online_store_product_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      sortOrder: 8,
      imagePath: 'public/OnlineStore/Content/category.jpg',
    );

    expect(payload['image_path'], 'public/OnlineStore/Content/category.jpg');
    expect(payload['name_translations'], {'ar': 'قطع', 'en': 'Parts'});
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
}
