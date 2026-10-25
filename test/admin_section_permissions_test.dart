import 'package:doctorbike/core/services/admin_section_permissions.dart';
import 'package:doctorbike/features/auth/data/models/user_model.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AdminSectionPermissions.sync('', null));

  test('existing managers keep access and an empty list grants no sections',
      () {
    AdminSectionPermissions.sync('admin', null);
    expect(AdminSectionPermissions.isManager, isTrue);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.ADDEDITADMINSCREEN),
        isTrue);
    AdminSectionPermissions.sync('admin', []);
    expect(AdminSectionPermissions.isManager, isFalse);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.SALESSCREEN), isFalse);
    expect(
        AdminSectionPermissions.allowsRoute(AppRoutes.PROFILESCREEN), isTrue);
  });

  test('section access includes details and quick actions without escalation',
      () {
    AdminSectionPermissions.sync('admin', ['sales', 'employees']);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.SALESSCREEN), isTrue);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.NEWINSTANTSALESCREEN),
        isTrue);
    expect(
        AdminSectionPermissions.allowsRoute(AppRoutes.SALESORDERDETAILSCREEN),
        isTrue);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.EMPLOYEESECTIONSCREEN),
        isTrue);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.ADDNEWEMPLOYEESCREEN),
        isFalse);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.ADDEDITADMINSCREEN),
        isFalse);
    expect(AdminSectionPermissions.allowsRoute(AppRoutes.STOCKSCREEN), isFalse);
    expect(
        AdminSectionPermissions.allowsRoute('/future-admin-screen'), isFalse);
  });

  test('dynamic conversations and query strings obey the assigned section', () {
    AdminSectionPermissions.sync('admin', ['store_support']);
    expect(AdminSectionPermissions.allowsRoute('/StoreSupport/42?source=store'),
        isTrue);
    expect(
        AdminSectionPermissions.allowsRoute('/TechnicalSupport/42'), isFalse);
    expect(AdminSectionPermissions.allowsRoute('/WhatsAppConversation/42'),
        isFalse);
  });

  test('session switching clears restrictions for the next identity', () {
    AdminSectionPermissions.sync('admin', []);
    expect(AdminSectionRouteGuard().redirect(AppRoutes.STOCKSCREEN)?.name,
        AppRoutes.BOTTOMNAVBARSCREEN);
    AdminSectionPermissions.sync('employee', null);
    expect(AdminSectionRouteGuard().redirect(AppRoutes.STOCKSCREEN), isNull);
    AdminSectionPermissions.sync('admin', null);
    expect(AdminSectionPermissions.isManager, isTrue);
  });

  test('saved session preserves the difference between full and empty access',
      () {
    Map<String, dynamic> payload(dynamic sections) => {
          'user': {'id': 1, 'type': 'admin', 'admin_sections': sections},
        };
    for (final sections in [
      null,
      <String>[],
      ['sales', 'stock']
    ]) {
      final user = UserModel.fromJson(payload(sections));
      final restored = UserModel.fromJson(user.toJson());
      expect(restored.user.adminSections, sections);
    }
  });
}
