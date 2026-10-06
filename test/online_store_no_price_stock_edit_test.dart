import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listing writable payload never contains base price or stock', () {
    final listing = OnlineStoreListing.fromJson({
      'id': 1,
      'product_id': 2,
      'title_translations': {'ar': 'منتج'},
      'base_prices': {'retail': 20},
      'availability': {'stock': 4},
      'updated_at': 'v1',
    });

    final payload = listing.toWritableJson();
    expect(payload['name_translations'], {'ar': 'منتج'});
    expect(payload.keys, isNot(contains('base_prices')));
    expect(payload.keys, isNot(contains('price')));
    expect(payload.keys, isNot(contains('stock')));
    expect(payload.keys, isNot(contains('availability')));
  });
}
