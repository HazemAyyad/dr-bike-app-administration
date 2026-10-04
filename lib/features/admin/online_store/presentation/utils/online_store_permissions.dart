import '../../../../../core/services/initial_bindings.dart';

class OnlineStorePermissions {
  const OnlineStorePermissions._();

  static bool allows(
    String permission, {
    String? type,
    Iterable<String>? permissions,
  }) {
    final resolvedType = type ?? userType;
    final resolved = permissions ?? employeePermissionNames;
    return resolvedType == 'admin' || resolved.contains(permission);
  }

  static bool get canView => allows(onlineStoreViewPermissionName);
  static bool get canManageProducts =>
      allows(onlineStoreProductsManagePermissionName);
  static bool get canManageCategories =>
      allows(onlineStoreCategoriesManagePermissionName);
  static bool get canManageContent =>
      allows(onlineStoreContentManagePermissionName);
  static bool get canManagePromotions =>
      allows(onlineStorePromotionsManagePermissionName);
  static bool get canManageReviews =>
      allows(onlineStoreReviewsManagePermissionName);
  static bool get canManageSettings =>
      allows(onlineStoreSettingsManagePermissionName);
}
