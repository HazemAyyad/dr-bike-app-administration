import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_media_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  test('select-main, visibility and reorder only mutate Store presentation',
      () {
    final source = [
      const OnlineStoreMedia(sourceMediaId: 10, sortOrder: 0, isMain: true),
      const OnlineStoreMedia(sourceMediaId: 11, sortOrder: 1),
    ];
    final controller = OnlineStoreMediaController(FakeOnlineStoreRepository());
    controller.items
      ..clear()
      ..addAll(source);

    controller.selectMain(11);
    controller.toggleVisible(10);
    controller.reorder(1, 0);

    expect(controller.items.first.sourceMediaId, 11);
    expect(controller.items.first.isMain, isTrue);
    expect(controller.items.last.isVisible, isFalse);
    expect(source.first.isMain, isTrue);
    expect(source.first.isVisible, isTrue);
  });

  test('main media cannot be hidden and missing main blocks readiness', () {
    final controller = OnlineStoreMediaController(FakeOnlineStoreRepository());
    controller.items
      ..clear()
      ..addAll([
        const OnlineStoreMedia(sourceMediaId: 1, sortOrder: 0, isMain: true),
      ]);
    controller.toggleVisible(1);
    expect(controller.items.single.isVisible, isTrue);

    final listing = OnlineStoreListing.fromJson({
      'id': 1,
      'product_id': 1,
      'readiness_state': 'blocked',
      'readiness_issues': ['main_media_required'],
    });
    expect(listing.canPublish, isFalse);
  });

  test('admin media response and replacement payload match Laravel contract',
      () {
    final media = OnlineStoreMedia.fromJson({
      'id': 8,
      'source_type': 'view_image',
      'source_id': 44,
      'resolved_path': 'public/products/bike.jpg',
      'is_main': true,
      'is_visible': true,
      'sort_order': 0,
    });

    expect(media.sourceMediaId, 8);
    expect(media.sourceId, 44);
    expect(media.url, 'public/products/bike.jpg');
    expect(media.toRequestJson(), {
      'source_type': 'view_image',
      'source_id': 44,
      'store_media_path': null,
      'is_main': true,
      'is_visible': true,
    });
  });
}
