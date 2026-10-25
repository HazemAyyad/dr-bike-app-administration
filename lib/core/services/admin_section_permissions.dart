import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

class AdminSectionPermissions {
  static final revision = 0.obs;
  static String _role = '';
  static List<String>? _sections;

  static bool get isManager => _role == 'admin' && _sections == null;
  static bool get isRestricted => _role == 'admin' && _sections != null;

  static void sync(String role, List<String>? sections) {
    final changed = role != _role ||
        (_sections == null) != (sections == null) ||
        (_sections != null &&
            sections != null &&
            (_sections!.length != sections.length ||
                !_sections!.every(sections.contains)));
    _role = role;
    _sections = sections == null ? null : List.unmodifiable(sections);
    if (changed) revision.value++;
  }

  static bool allows(String section) =>
      !isRestricted || _sections!.contains(section);

  static bool allowsRoute(String? route) {
    if (!isRestricted || route == null || route.isEmpty) return true;
    final normalized = route.split('?').first;
    for (final entry in routeSections.entries) {
      final pattern = entry.key.replaceAll(RegExp(r':\w+'), r'[^/]+');
      if (RegExp('^$pattern\$').hasMatch(normalized)) {
        return entry.value != 'manager' && entry.value.split('|').any(allows);
      }
    }
    return sharedRoutes.contains(normalized);
  }

  static const sharedRoutes = {
    AppRoutes.SPLASHSCREEN,
    AppRoutes.NOINTERNETSCREEN,
    AppRoutes.BOTTOMNAVBARSCREEN,
    AppRoutes.ADMINDASHBOARDSCREEN,
    AppRoutes.LOGINSCREEN,
    AppRoutes.LOGINORSIGNUPSCREEN,
    AppRoutes.PROFILESCREEN,
    AppRoutes.PERSONALDETAILSSCREEN,
    AppRoutes.CHANGEPASSWORDSCREEN,
    AppRoutes.CONTACTUSSCREEN,
  };

  static const Map<String, String> routeSections = {
    AppRoutes.ACCOUNTINGREPORTSSCREEN: 'accounting',
    AppRoutes.ACTIVITYLOGSCREEN: 'employees',
    AppRoutes.ADDCOMBINATIONSCREEN: 'stock',
    AppRoutes.ADDEDITADMINSCREEN: 'manager',
    AppRoutes.ADDEDITOFFERPACKAGESCREEN: 'stock',
    AppRoutes.ADDEXPENSESCREEN: 'finance',
    AppRoutes.ADDFOLLOWUPSCREEN: 'follow_up',
    AppRoutes.ADDNEWASSETSCREEN: 'finance',
    AppRoutes.ADDNEWBILLSCREEN: 'purchases',
    AppRoutes.ADDNEWCUSTOMERSCREEN: 'people',
    AppRoutes.ADDNEWEMPLOYEESCREEN: 'manager',
    AppRoutes.ADDNEWTARGETSCREEN: 'goals',
    AppRoutes.ADDPRODUCTMANAGEMENTSCREEN: 'product_development',
    AppRoutes.ADJUSTMENTSALEPRODUCTPICKER: 'sales',
    AppRoutes.ADMINACTIVTILOGSCREEN: 'manager',
    AppRoutes.APPDEVELOPMENT: 'app_development',
    AppRoutes.APPDEVELOPMENTTASK: 'app_development',
    AppRoutes.APPVERSIONREPORTSCREEN: 'app_development',
    AppRoutes.ASSETDETAILSSCREEN: 'finance',
    AppRoutes.ASSETLOGSCREEN: 'finance',
    AppRoutes.ASSETSSCREEN: 'finance',
    AppRoutes.ATTENDANCEDEVICESSCREEN: 'settings',
    AppRoutes.ATTENDANCEREPORTSCREEN: 'employees',
    AppRoutes.ATTENDANCESETTINGSSCREEN: 'settings',
    AppRoutes.BANKSSETTINGSSCREEN: 'settings',
    AppRoutes.BILLDETAILSSCREEN: 'purchases',
    AppRoutes.BILLSSCREEN: 'purchases',
    AppRoutes.BOXESSCREEN: 'boxes',
    AppRoutes.BUYINGSCREEN: 'purchases',
    AppRoutes.CATEGORYMANAGEMENTSCREEN: 'stock',
    AppRoutes.CHECKNOTIFICATIONRULESSCREEN: 'checks',
    AppRoutes.CHECKSSCREEN: 'checks',
    AppRoutes.CLOSEOUTSSCREEN: 'stock',
    AppRoutes.CONTACTCATEGORIESSETTINGSSCREEN: 'settings',
    AppRoutes.COUNTERSSCREEN: 'reports',
    AppRoutes.CREATEPROJECTSCREEN: 'projects',
    AppRoutes.CREATEPURCHASERETURNSCREEN: 'purchases',
    AppRoutes.CREATETASKSCREEN: 'employee_tasks|special_tasks',
    AppRoutes.CURRENTFOLLOWUPSCREEN: 'follow_up',
    AppRoutes.DAILYBOXESSCREEN: 'daily_boxes',
    AppRoutes.DATABASEBACKUPSSCREEN: 'manager',
    AppRoutes.DEBTSSCREEN: 'debts',
    AppRoutes.DELIVERYCOMPANYACCOUNTSSCREEN: 'sales',
    AppRoutes.DESTRUCTIONPRODUCTSSCREEN: 'finance',
    AppRoutes.EDITBOXESSCREEN: 'boxes',
    AppRoutes.EDITCHECKSCREEN: 'checks',
    AppRoutes.EDITPRODUCTSCREEN: 'stock',
    AppRoutes.EMPLOYEEATTENDANCEHISTORY: 'employees',
    AppRoutes.EMPLOYEEDETAILSSCREEN: 'employees',
    AppRoutes.EMPLOYEEPOINTCATEGORIESSCREEN: 'employees',
    AppRoutes.EMPLOYEEPOINTRULESSCREEN: 'employees',
    AppRoutes.EMPLOYEEPOINTSREPORTSCREEN: 'employees',
    AppRoutes.EMPLOYEEPOINTSSETTINGSSCREEN: 'employees',
    AppRoutes.EMPLOYEEREMINDERSSCREEN: 'reminders',
    AppRoutes.EMPLOYEEREWARDRULESSCREEN: 'employees',
    AppRoutes.EMPLOYEESECTIONSCREEN: 'employees',
    AppRoutes.EMPLOYEESIGNATURESSCREEN: 'employees',
    AppRoutes.EMPLOYEESUGGESTIONSSCREEN: 'suggestions',
    AppRoutes.EMPLOYEETASKPERFORMANCE: 'employee_tasks',
    AppRoutes.EMPLOYEETASKSSCREEN: 'employee_tasks',
    AppRoutes.EMPLOYEEWIFIPRESENCEHISTORYSCREEN: 'settings',
    AppRoutes.EXPENSEACCOUNTINGSCREEN: 'accounting',
    AppRoutes.EXPENSEDETAILSSCREEN: 'finance',
    AppRoutes.FILEBOXSCREEN: 'boxes',
    AppRoutes.FILESSCREEN: 'boxes',
    AppRoutes.FINANCIALAFFAIRSSCREEN: 'finance',
    AppRoutes.FINGERPRINTDEVICELOGSSCREEN: 'settings',
    AppRoutes.FINGERPRINTDEVICEUSERSSCREEN: 'settings',
    AppRoutes.GENERALDATALISTSCREEN: 'people',
    AppRoutes.GENERALSETTINGSSCREEN: 'settings',
    AppRoutes.GLOBALEMPLOYEEPOINTSSCREEN: 'employees',
    AppRoutes.INCOMEACCOUNTINGSCREEN: 'accounting',
    AppRoutes.INCOMINGCHECKSSCREEN: 'checks',
    AppRoutes.INSTANTSALEBILLDETAILSSCREEN: 'sales',
    AppRoutes.INSTANTSALEPRODUCTPICKER: 'sales',
    AppRoutes.MAINTENANCEDAILYADMINSCREEN: 'maintenance',
    AppRoutes.MAINTENANCEDAILYCLOSESCREEN: 'maintenance',
    AppRoutes.MAINTENANCEDAILYHISTORYSCREEN: 'maintenance',
    AppRoutes.MAINTENANCESCREEN: 'maintenance',
    AppRoutes.MAINTENANCESERVICESSETTINGSSCREEN: 'maintenance',
    AppRoutes.METACATALOGSYNC: 'social_catalog',
    AppRoutes.MYEMPLOYEEREMINDERSSCREEN: 'reminders',
    AppRoutes.MYEMPLOYEESUGGESTIONSSCREEN: 'suggestions',
    AppRoutes.NEWADJUSTMENTSALESCREEN: 'sales',
    AppRoutes.NEWCASHPROFITSCREEN: 'sales',
    AppRoutes.NEWCHECKSCREEN: 'checks',
    AppRoutes.NEWINSTANTSALESCREEN: 'sales',
    AppRoutes.NEWMAINTENANCESCREEN: 'maintenance',
    AppRoutes.NEWSALESORDERSCREEN: 'sales',
    AppRoutes.NOTEDETAIL: 'notes',
    AppRoutes.NOTES: 'notes',
    AppRoutes.NOTIFICATIONCENTER: 'manager',
    AppRoutes.NOTIFICATIONSETTINGSCENTER: 'notification_settings',
    AppRoutes.OFFERPACKAGESSCREEN: 'stock',
    AppRoutes.OFFICIALPAPERSSCREEN: 'finance',
    AppRoutes.ONLINESTOREACCOUNTS: 'online_store',
    AppRoutes.ONLINESTOREAUDIT: 'online_store',
    AppRoutes.ONLINESTOREBANNERS: 'online_store',
    AppRoutes.ONLINESTORECATEGORIES: 'online_store',
    AppRoutes.ONLINESTORECOUPONS: 'online_store',
    AppRoutes.ONLINESTORECREDIT: 'online_store',
    AppRoutes.ONLINESTOREDASHBOARD: 'online_store',
    AppRoutes.ONLINESTOREHOMESECTIONS: 'online_store',
    AppRoutes.ONLINESTORELISTINGEDITOR: 'online_store',
    AppRoutes.ONLINESTORELISTINGS: 'online_store',
    AppRoutes.ONLINESTOREMEDIA: 'online_store',
    AppRoutes.ONLINESTORENOTIFICATIONBROADCASTS: 'online_store',
    AppRoutes.ONLINESTOREPOPUPCAMPAIGNS: 'online_store',
    AppRoutes.ONLINESTOREPRODUCTPICKER: 'online_store',
    AppRoutes.ONLINESTOREPROMOTIONS: 'online_store',
    AppRoutes.ONLINESTOREREPORTS: 'online_store',
    AppRoutes.ONLINESTOREREVIEWS: 'online_store',
    AppRoutes.ONLINESTORESETTINGS: 'online_store',
    AppRoutes.ONLINESTORESTATISTICS: 'online_store',
    AppRoutes.OUTGOINGCHECKSSCREEN: 'checks',
    AppRoutes.PAYROLLSCREEN: 'employees',
    AppRoutes.POINTSTABLE: 'employees',
    AppRoutes.PRIVATETASKSSCREEN: 'special_tasks',
    AppRoutes.PRODUCTASSEMBLYOPERATIONSSCREEN: 'stock',
    AppRoutes.PRODUCTDETAILSSCREEN: 'stock',
    AppRoutes.PRODUCTMANAGEMENTSCREEN: 'product_development',
    AppRoutes.PRODUCTSIZEOPTIONSSETTINGSSCREEN: 'settings',
    AppRoutes.PRODUCTSTOCKMOVEMENTSSCREEN: 'stock',
    AppRoutes.PROJECTDETAILSSCREEN: 'projects',
    AppRoutes.PROJECTMANAGEMENTSCREEN: 'projects',
    AppRoutes.PURCHASEORDERSSCREEN: 'purchases',
    AppRoutes.PURCHASERETURNDETAILSSCREEN: 'purchases',
    AppRoutes.QRHISTORYSCREEN: 'employees',
    AppRoutes.REPORTDETAILSCREEN: 'reports',
    AppRoutes.REPORTSSCREEN: 'reports',
    AppRoutes.RETURNPURCHASESSCREEN: 'purchases',
    AppRoutes.SAFESSCREEN: 'boxes',
    AppRoutes.SALARYPERIODDETAILSSCREEN: 'employees',
    AppRoutes.SALESACCOUNTINGSCREEN: 'accounting',
    AppRoutes.SALESDAILYADMINSCREEN: 'daily_boxes',
    AppRoutes.SALESDAILYCLOSESCREEN: 'sales|daily_boxes',
    AppRoutes.SALESDAILYHISTORYSCREEN: 'daily_boxes',
    AppRoutes.SALESDAILYSESSIONDETAILSCREEN: 'sales|daily_boxes',
    AppRoutes.SALESORDERCHECKOUTSCREEN: 'sales',
    AppRoutes.SALESORDERDETAILSCREEN: 'sales',
    AppRoutes.SALESRETURNCHECKOUT: 'sales',
    AppRoutes.SALESRETURNPERSON: 'sales',
    AppRoutes.SALESRETURNPRODUCTPICKER: 'sales',
    AppRoutes.SALESSCREEN: 'sales',
    AppRoutes.SALESSETTINGSSCREEN: 'sales',
    AppRoutes.SMARTHOMESCREEN: 'smart_home',
    AppRoutes.SPECIALTASKDETAILSSCREEN: 'special_tasks',
    AppRoutes.STOCKIMAGESEXPORTSSCREEN: 'stock',
    AppRoutes.STOCKINVENTORYSETTINGSSCREEN: 'settings',
    AppRoutes.STOCKSCREEN: 'stock',
    AppRoutes.STORESECTIONSSETTINGSSCREEN: 'settings',
    AppRoutes.STORESUPPORT: 'store_support',
    AppRoutes.STORESUPPORTCONVERSATION: 'store_support',
    AppRoutes.SUSPENDEDINVOICESSCREEN: 'sales',
    AppRoutes.TARGETDETAILSSCREEN: 'goals',
    AppRoutes.TARGETSECTIONSCREEN: 'goals',
    AppRoutes.TASKDETAILS: 'employee_tasks',
    AppRoutes.TASKRECURRENCE: 'employee_tasks',
    AppRoutes.TECHNICALSUPPORT: 'support',
    AppRoutes.TECHNICALSUPPORTCONVERSATION: 'support',
    AppRoutes.THEEXPENSESSCREEN: 'finance',
    AppRoutes.WHATSAPPCENTER: 'social',
    AppRoutes.WHATSAPPCONVERSATION: 'social',
  };
}

class AdminSectionRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      AdminSectionPermissions.allowsRoute(route)
          ? null
          : const RouteSettings(name: AppRoutes.BOTTOMNAVBARSCREEN);
}
