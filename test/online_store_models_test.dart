import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses listing readiness, derived price, stock and media', () {
    final listing = OnlineStoreListing.fromJson({
      'id': 7,
      'product_id': 22,
      'status': 'ready',
      'readiness_state': 'ready',
      'readiness_issues': [],
      'base_prices': {'retail': 99},
      'availability': {'in_stock': true},
      'detail_presentation': {
        'quick_specs': [
          {
            'icon': 'speed',
            'label_translations': {'ar': 'السرعة'},
            'value_translations': {'ar': '25 كم/ساعة'},
          },
        ],
      },
      'media': [
        {
          'source_media_id': 3,
          'sort_order': 0,
          'is_main': true,
          'media_metadata': {'media_type': 'video', 'role': 'video'},
        },
      ],
    });

    expect(listing.canPublish, isTrue);
    expect(listing.basePrices['retail'], 99);
    expect(listing.availability['in_stock'], isTrue);
    expect(listing.media.single.isMain, isTrue);
    expect(listing.media.single.mediaType, 'video');
    expect(listing.media.single.role, 'video');
    expect((listing.detailPresentation['quick_specs'] as List), hasLength(1));
  });

  test('product picker preserves all image sources and product video', () {
    final product = OnlineStoreProductCandidate.fromJson({
      'id': 31,
      'nameAr': 'منتج متعدد الوسائط',
      'product_viewImages': [
        {'imageUrl': 'view.jpg'},
      ],
      'product_normalImages': [
        {'imageUrl': 'normal.jpg'},
      ],
      'product_image3d': [
        {'imageUrl': '3d.jpg'},
      ],
      'product_variantImages': ['variant.jpg'],
      'product_video': 'product.mp4',
    });

    expect(
        product.imageUrls, ['view.jpg', 'normal.jpg', '3d.jpg', 'variant.jpg']);
    expect(product.videoUrl, 'product.mp4');
  });

  test('complete backend readiness is publishable', () {
    final listing = OnlineStoreListing.fromJson({
      'id': 1,
      'product_id': 2,
      'readiness_state': 'complete',
      'readiness_issues': <dynamic>[],
    });

    expect(listing.canPublish, isTrue);
  });

  test('parses unlinked, blocked and dual-role Store accounts once', () {
    final account = OnlineStoreAccount.fromJson({
      'id': 9,
      'name': 'Store User',
      'is_blocked': true,
      'is_linkable': false,
      'links': [
        {'id': 1, 'role': 'customer', 'status': 'active'},
        {'id': 2, 'role': 'seller', 'status': 'active'},
      ],
    });

    expect(account.isBlocked, isTrue);
    expect(account.isLinkable, isFalse);
    expect(account.links.map((e) => e.role), ['customer', 'seller']);
    expect(
        OnlineStoreAccount.fromJson({'id': 10, 'name': 'New', 'links': []})
            .links,
        isEmpty);
  });

  test('parses ledger-derived credit without a writable balance', () {
    final credit = OnlineStoreCreditSnapshot.fromJson({
      'policy': {'is_eligible': true, 'limit': 500, 'currency': 'ILS'},
      'current_debt': 125,
      'available_credit': 375,
      'as_of': '2026-10-04T10:00:00Z',
    });
    expect(credit.currentDebt, 125);
    expect(credit.availableCredit, 375);
  });
}
