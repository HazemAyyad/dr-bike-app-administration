import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  test('authoritative admin endpoint constants match backend routes', () {
    expect(EndPoints.onlineStoreListings, 'online-store/listings');
    expect(EndPoints.onlineStoreAccounts, 'online-store/accounts');
    expect(EndPoints.onlineStoreReports, 'online-store/reports');
    expect(EndPoints.onlineStoreAuditEvents, 'online-store/audit-events');
  });

  test('request shapes exclude authoritative price and stock writes', () async {
    final fake = FakeOnlineStoreRepository();
    await fake.post(EndPoints.onlineStoreListings, data: {'product_id': 17});
    expect(fake.lastData, {'product_id': 17});
    expect(fake.lastData, isNot(contains('price')));
    expect(fake.lastData, isNot(contains('stock')));
  });

  test('actual account linking contract uses account-links', () async {
    final fake = FakeOnlineStoreRepository();
    await fake.post(EndPoints.onlineStoreAccountLinks, data: {
      'user_id': 4,
      'party_type': 'customer',
      'party_id': 11,
    });
    expect(fake.calls.single, 'POST online-store/account-links');
  });
}
