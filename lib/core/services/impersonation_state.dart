import 'final_classes.dart';

class ImpersonationState {
  ImpersonationState._();

  static const originalTokenKey = 'impersonation_admin_token';
  static const originalUserKey = 'impersonation_admin_user_json';
  static const originalNameKey = 'impersonation_admin_name';
  static const originalTypeKey = 'impersonation_impersonator_type';

  static bool get isActive {
    final token = FinalClasses.getStorage.read(originalTokenKey);
    return token != null && token.toString().isNotEmpty;
  }

  static bool get isAdminImpersonatingEmployee {
    final type = FinalClasses.getStorage.read(originalTypeKey)?.toString();
    return isActive && (type == null || type.isEmpty || type == 'admin');
  }
}
