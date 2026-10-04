import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/online_store/data/online_store_datasource.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_audit_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_banners_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_categories_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_coupons_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_home_sections_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_promotions_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_reports_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_resource_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_settings_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_banner_editor.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_discount_editor.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_resource_screen.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_target_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide MultipartFile, Response;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_lib;

import 'helpers/fake_online_store_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('typed reorder methods send exact backend keys', () async {
    final fake = FakeOnlineStoreRepository();
    await OnlineStoreCategoriesController(fake).reorderCategories([3, 1, 2]);
    expect(fake.lastData, {
      'category_ids': [3, 1, 2]
    });

    await OnlineStoreHomeSectionsController(fake).reorderSections([8, 4]);
    expect(fake.lastData, {
      'section_ids': [8, 4]
    });

    await OnlineStoreBannersController(fake).reorderBanners([9, 7, 6]);
    expect(fake.lastData, {
      'banner_ids': [9, 7, 6]
    });
  });

  test('datasource reorder requests use exact backend payload contracts',
      () async {
    final api = _RecordingApiConsumer();
    final datasource = OnlineStoreDatasource(api: api);
    await datasource.reorderCategories([3, 1, 2]);
    await datasource.reorderHomeSections([8, 4]);
    await datasource.reorderBanners([9, 7, 6]);
    expect(api.requests, [
      {
        'path': 'online-store/categories/reorder',
        'data': {
          'category_ids': [3, 1, 2]
        },
        'is_form_data': false,
      },
      {
        'path': 'online-store/home-sections/reorder',
        'data': {
          'section_ids': [8, 4]
        },
        'is_form_data': false,
      },
      {
        'path': 'online-store/banners/reorder',
        'data': {
          'banner_ids': [9, 7, 6]
        },
        'is_form_data': false,
      },
    ]);
  });

  testWidgets('resource menu hides unsupported activate actions',
      (tester) async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/categories'] = {
      'data': [
        {'id': 1, 'name': 'خوذ'}
      ]
    };
    final controller =
        OnlineStoreResourceController(fake, EndPoints.onlineStoreCategories);
    Get.put(controller);
    await controller.load();
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnlineStoreResourceScreen<OnlineStoreResourceController>(
          title: 'التصنيفات',
          icon: Icons.category,
          canManage: true,
          actions: {OnlineStoreResourceAction.delete},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final menu =
        find.byWidgetPredicate((widget) => widget is PopupMenuButton<String>);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('حذف'), findsOneWidget);
    expect(find.text('تفعيل'), findsNothing);
    expect(find.text('إيقاف'), findsNothing);
  });

  testWidgets('promotions and coupons may show activate actions',
      (tester) async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/promotions'] = {
      'data': [
        {'id': 2, 'name': 'عرض'}
      ]
    };
    final controller =
        OnlineStoreResourceController(fake, EndPoints.onlineStorePromotions);
    Get.put(controller);
    await controller.load();
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnlineStoreResourceScreen<OnlineStoreResourceController>(
          title: 'العروض',
          icon: Icons.local_offer,
          canManage: true,
          actions: {
            OnlineStoreResourceAction.activate,
            OnlineStoreResourceAction.deactivate,
            OnlineStoreResourceAction.delete,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final menu =
        find.byWidgetPredicate((widget) => widget is PopupMenuButton<String>);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('تفعيل'), findsOneWidget);
    expect(find.text('إيقاف'), findsOneWidget);
  });

  testWidgets('permission-hidden resource has no mutation menu',
      (tester) async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/banners'] = {
      'data': [
        {'id': 4, 'name': 'بانر'}
      ]
    };
    final controller =
        OnlineStoreResourceController(fake, EndPoints.onlineStoreBanners);
    Get.put(controller);
    await controller.load();
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnlineStoreResourceScreen<OnlineStoreResourceController>(
          title: 'البانرات',
          icon: Icons.image,
          canManage: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton<String>),
        findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  test('banner destinations support promotion and clear incompatible fields',
      () {
    expect(
      onlineStoreBannerDestination('promotion', targetId: 12, url: 'ignored'),
      {
        'action_type': 'promotion',
        'action_target_id': 12,
        'action_url': null,
      },
    );
    expect(
      onlineStoreBannerDestination('url', targetId: 12, url: ' https://x '),
      {
        'action_type': 'url',
        'action_target_id': null,
        'action_url': 'https://x',
      },
    );
    expect(onlineStoreBannerDestination('none'), {
      'action_type': 'none',
      'action_target_id': null,
      'action_url': null,
    });
  });

  test('promotion and coupon targets are typed and global clears rows', () {
    const targets = [
      OnlineStoreTargetOption(type: 'listing', id: 3, label: 'A'),
      OnlineStoreTargetOption(type: 'category', id: 7, label: 'B'),
    ];
    expect(onlineStoreDiscountTargets('targeted', targets), [
      {'target_type': 'listing', 'target_id': 3},
      {'target_type': 'category', 'target_id': 7},
    ]);
    expect(onlineStoreDiscountTargets('global', targets), isEmpty);
  });

  test('customer and seller discovery uses authoritative role endpoints',
      () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['parties:customer'] = {
      'data': [
        {'id': 3, 'name': 'عميل'}
      ]
    };
    fake.responses['parties:seller'] = {
      'data': [
        {'id': 8, 'name': 'مورد'}
      ]
    };
    expect((await fake.parties('customer')).single.name, 'عميل');
    expect(fake.calls.last, 'GET all/customers');
    expect((await fake.parties('seller')).single.name, 'مورد');
    expect(fake.calls.last, 'GET all/sellers');
  });

  test('settings payload includes complete typed contract', () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/settings'] = {'data': {}};
    final controller = OnlineStoreSettingsController(fake);
    controller.values.addAll({
      'store_enabled': true,
      'maintenance_mode': false,
      'checkout_enabled': true,
      'cod_enabled': true,
      'guest_browsing_enabled': true,
      'minimum_order': 50,
      'support_phone': '02',
      'whatsapp': '059',
      'enabled_languages': ['ar', 'en'],
      'cancellation_policy_translations': {'ar': 'إلغاء', 'en': 'Cancel'},
      'return_policy_translations': {'ar': 'إرجاع', 'en': 'Return'},
      'warranty_policy_translations': {'ar': 'ضمان', 'en': 'Warranty'},
      'terms_translations': {'ar': 'شروط', 'en': 'Terms'},
      'out_of_stock_behavior': 'visible_non_purchasable',
      'low_stock_threshold': 4,
    });
    await controller.save();
    expect(fake.lastData, containsPair('enabled_languages', ['ar', 'en']));
    expect(fake.lastData, containsPair('low_stock_threshold', 4));
    expect(fake.lastData,
        containsPair('out_of_stock_behavior', 'visible_non_purchasable'));
    expect(fake.lastData, contains('terms_translations'));
    expect(fake.lastData, isNot(contains('price')));
    expect(fake.lastData, isNot(contains('stock')));
  });

  test('audit reports promotions coupons use their authoritative workflows',
      () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/audit-events'] = {'data': []};
    fake.responses['GET online-store/reports'] = {'data': {}};
    await OnlineStoreAuditController(fake).load();
    final reports = OnlineStoreReportsController(fake);
    reports.origin.value = 'store';
    await reports.load();
    await OnlineStorePromotionsController(fake).action(2, 'activate');
    await OnlineStoreCouponsController(fake).action(3, 'deactivate');
    expect(fake.calls, contains('GET online-store/audit-events'));
    expect(fake.calls, contains('GET online-store/reports'));
    expect(fake.calls, contains('POST online-store/promotions/2/activate'));
    expect(fake.calls, contains('POST online-store/coupons/3/deactivate'));
  });

  test('banner image upload uses multipart file field and approved endpoint',
      () async {
    final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}banner_contract.png');
    await file.writeAsBytes(
        image_lib.encodePng(image_lib.Image(width: 1, height: 1)));
    final api = _RecordingApiConsumer();
    final datasource = OnlineStoreDatasource(api: api);
    final response = await datasource.uploadContentImage(XFile(file.path));
    expect(api.path, EndPoints.onlineStoreContentImages);
    expect(api.isFormData, isTrue);
    expect(api.data!.keys, ['file']);
    expect(api.data!['file'], isA<MultipartFile>());
    expect(response['data']['image_path'],
        'public/OnlineStore/Content/banner.png');
    await file.delete();
  });
}

class _RecordingApiConsumer implements ApiConsumer {
  String? path;
  Map<String, dynamic>? data;
  bool? isFormData;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Function(int, int)? onSendProgress,
  }) async {
    this.path = path;
    this.data = Map<String, dynamic>.from(data! as Map);
    this.isFormData = isFormData;
    requests.add({
      'path': path,
      'data': this.data,
      'is_form_data': isFormData,
    });
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: {
        'data': {
          'image_path': 'public/OnlineStore/Content/banner.png',
        }
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
