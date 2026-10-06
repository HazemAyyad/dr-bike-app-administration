import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_accounts_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_categories_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_credit_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_home_sections_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_listings_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_reports_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_reviews_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  test('listing lifecycle preserves server readiness and concurrency token',
      () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['listings'] = {
      'data': [
        {
          'id': 4,
          'product_id': 8,
          'status': 'ready',
          'readiness_state': 'ready',
          'updated_at': 'v2',
        }
      ],
    };
    fake.responses['transition'] = {
      'id': 4,
      'product_id': 8,
      'status': 'published',
      'readiness_state': 'ready',
      'updated_at': 'v3',
    };
    final controller = OnlineStoreListingsController(fake);
    await controller.load();
    await controller.transition(controller.items.single, 'published');

    expect(fake.lastData, {'status': 'published', 'updated_at': 'v2'});
    expect(controller.items.single.status, 'published');
  });

  test('account search returns one dual-role user and uses explicit role link',
      () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['accounts'] = {
      'data': [
        {
          'id': 3,
          'name': 'Dual',
          'links': [
            {'id': 10, 'role': 'customer'},
            {'id': 11, 'role': 'seller'},
          ],
        }
      ],
    };
    final controller = OnlineStoreAccountsController(fake);
    controller.search.text = 'Dual';
    await controller.load();
    await controller.link(userId: 3, role: 'seller', partyId: 15);

    expect(controller.accounts, hasLength(1));
    expect(controller.accounts.single.links, hasLength(2));
    expect(fake.lastData, {
      'user_id': 3,
      'role': 'seller',
      'seller_id': 15,
      'account_source': 'admin_app',
      'status': 'active',
    });
  });

  test('category and home replacements send complete deterministic order',
      () async {
    final fake = FakeOnlineStoreRepository();
    final categories = OnlineStoreCategoriesController(fake);
    await categories.replaceListings(4, [9, 7]);
    expect(fake.calls.last, 'PUT online-store/categories/4/listings');
    expect(fake.lastData, {
      'items': [
        {'listing_id': 9, 'sort_order': 0},
        {'listing_id': 7, 'sort_order': 1},
      ]
    });

    final sections = OnlineStoreHomeSectionsController(fake);
    await sections.replaceItems(2, [
      {'target_type': 'listing', 'target_id': 9, 'sort_order': 0}
    ]);
    expect(fake.calls.last, 'PUT online-store/home-sections/2/items');
  });

  test('credit policy writes eligibility while debt remains server-derived',
      () async {
    final fake = FakeOnlineStoreRepository();
    fake.responses['GET online-store/account-links/5/credit'] = {
      'data': {
        'policy': {'is_eligible': true, 'credit_limit': 300, 'currency': 'ILS'},
        'current_debt': 25,
        'available_credit': 275,
      }
    };
    final credit = OnlineStoreCreditController(fake);
    await credit.load(5);
    await credit.savePolicy(eligible: true, limit: 300, currency: 'ILS');
    expect(fake.lastData, containsPair('credit_limit', 300));
    expect(fake.lastData, isNot(contains('current_debt')));
  });

  test('moderation, settings precedence and report origin stay authoritative',
      () async {
    final fake = FakeOnlineStoreRepository();
    final reviews = OnlineStoreReviewsController(fake);
    await reviews.moderate(3, 'rejected', reason: 'محتوى غير مناسب');
    expect(fake.calls, contains('POST online-store/reviews/3/moderate'));
    expect(fake.lastData, containsPair('reason', 'محتوى غير مناسب'));

    final settings = OnlineStoreSettingsController(fake);
    settings.values
      ..clear()
      ..addAll({'store_enabled': true, 'maintenance_mode': true});
    expect(settings.effectiveOperatingState, 'maintenance');

    fake.responses['GET online-store/reports'] = {'data': {}};
    final reports = OnlineStoreReportsController(fake);
    reports.origin.value = 'store';
    reports.accountType.value = 'seller';
    await reports.load();
    expect(fake.lastQuery, containsPair('origin', 'store'));
    expect(fake.lastQuery, containsPair('account_type', 'seller'));
  });
}
