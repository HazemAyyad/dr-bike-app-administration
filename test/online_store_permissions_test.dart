import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/admin/online_store/presentation/utils/online_store_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin bypasses all Online Store permission checks', () {
    expect(
        OnlineStorePermissions.allows(
          onlineStoreSettingsManagePermissionName,
          type: 'admin',
          permissions: const [],
        ),
        isTrue);
  });

  test('employee entry and actions require exact permission names', () {
    expect(
        OnlineStorePermissions.allows(
          onlineStoreViewPermissionName,
          type: 'employee',
          permissions: const [onlineStoreViewPermissionName],
        ),
        isTrue);
    expect(
        OnlineStorePermissions.allows(
          onlineStoreProductsManagePermissionName,
          type: 'employee',
          permissions: const [onlineStoreViewPermissionName],
        ),
        isFalse);
    expect(
        OnlineStorePermissions.allows(
          onlineStoreProductsManagePermissionName,
          type: 'employee',
          permissions: const [onlineStoreProductsManagePermissionName],
        ),
        isTrue);
  });

  test('all seven permission names stay exact', () {
    expect({
      onlineStoreViewPermissionName,
      onlineStoreProductsManagePermissionName,
      onlineStoreCategoriesManagePermissionName,
      onlineStoreContentManagePermissionName,
      onlineStorePromotionsManagePermissionName,
      onlineStoreReviewsManagePermissionName,
      onlineStoreSettingsManagePermissionName,
    }, hasLength(7));
  });
}
