import 'dart:ui';

import 'package:get/get.dart';

import 'package:doctorbike/features/App_entr/on_boarding/widgets/login_or_sign_up.dart';
import 'package:doctorbike/features/admin/stock/presentation/binding/stock_binding.dart';
import 'package:doctorbike/features/admin/stock/presentation/views/stock_screen.dart';
import 'package:doctorbike/features/auth/presentation/login/views/login_screen.dart';
import 'package:doctorbike/features/employee/employee_dashbord/data/repositories/employee_dashbord_implement.dart';
import 'package:doctorbike/features/employee/employee_dashbord/domain/usecases/get_my_attendance_history_usecase.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/binding/employee_dashbord_binding.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/controllers/my_attendance_history_controller.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/views/employee_dashbord_screen.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/views/my_attendance_history_screen.dart';
import 'package:doctorbike/features/home/views/home_page_screen.dart';

import '../features/App_entr/no_internet/view/no_internet_screen.dart';
import '../features/App_entr/on_boarding/binding/onboarding_binding.dart';
import '../features/App_entr/on_boarding/view/on_boarding_screen.dart';
import '../features/App_entr/on_boarding/widgets/chose_lang.dart';
import '../features/App_entr/splash/binding/splash_binding.dart';
import '../features/App_entr/splash/view/splash_screen.dart';
import '../features/admin/buying/presentation/views/bills_screens/add_new_bill_screen.dart';
import '../features/admin/buying/presentation/views/bills_screens/bill_details_screen.dart';
import '../features/admin/buying/presentation/views/purchase_orders_screen/purchase_orders_screen.dart';
import '../features/admin/buying/presentation/views/return_purchases_screens/return_purchases_screen.dart';
import '../features/admin/follow_up/presentation/binding/follow_up_binding.dart';
import '../features/admin/follow_up/presentation/views/follow_up_screen.dart';
import '../features/admin/follow_up/presentation/views/add_new_follow_up.dart';
import '../features/admin/admin_dashbord/presentation/binding/admin_dashboard_binding.dart';
import '../features/admin/admin_dashbord/presentation/views/admin_activti_log_screen.dart';
import '../features/admin/notifications/presentation/bindings/admin_notification_center_binding.dart';
import '../features/admin/notifications/presentation/views/admin_notification_center_screen.dart';
import '../features/employee/notifications/presentation/bindings/employee_notification_center_binding.dart';
import '../features/employee/notifications/presentation/views/employee_notification_center_screen.dart';
import '../features/employee_reminders/presentation/employee_reminders_screen.dart';
import '../features/admin/admin_dashbord/presentation/views/admin_dashboard_screen.dart';
import '../features/admin/boxes/presentation/binding/boxes_binding.dart';
import '../features/admin/boxes/presentation/views/boxes_screen.dart';
import '../features/admin/boxes/presentation/views/create_boxes_screen.dart';
import '../features/admin/boxes/presentation/views/edit_boxes_screen.dart';
import '../features/admin/buying/presentation/binding/buying_binding.dart';
import '../features/admin/buying/presentation/views/bills_screens/bills_screen.dart';
import '../features/admin/buying/presentation/views/buying_screen.dart';
import '../features/admin/checks/presentation/binding/checks_binding.dart';
import '../features/admin/checks/presentation/views/checks_screen.dart';
import '../features/admin/checks/presentation/views/check_notification_rules_screen.dart';
import '../features/admin/checks/presentation/views/incoming_checks_screen.dart';
import '../features/admin/checks/presentation/views/new_check_screen.dart';
import '../features/admin/checks/presentation/views/outgoing_checks_screen.dart';
import '../features/admin/counters/presentation/binding/counters_binding.dart';
import '../features/admin/counters/presentation/views/counters_screen.dart';
import '../features/admin/create_tasks/presentation/binding/create_task_binding.dart';
import '../features/admin/create_tasks/presentation/views/create_task_entry_screen.dart';
import '../features/admin/create_tasks/presentation/views/task_recurrence_screen.dart';
import '../features/admin/employee_tasks/presentation/views/employee_task_performance_screen.dart';
import '../features/admin/debts/presentation/binding/debts_binding.dart';
import '../features/admin/debts/presentation/views/debts_screen.dart';
import '../features/admin/employee_section/presentation/binding/employee_section_binding.dart';
import '../features/admin/employee_section/presentation/views/activity_log_screen.dart';
import '../features/admin/employee_section/presentation/views/add_new_employee_screen.dart';
import '../features/admin/employee_section/presentation/views/add_penalty_and_reward.dart';
import '../features/admin/employee_section/presentation/views/employee_details_screen.dart';
import '../features/admin/employee_section/data/repositorie_imp/employee_implement.dart';
import '../features/admin/employee_section/domain/usecases/get_attendance_report_usecase.dart';
import '../features/admin/employee_section/domain/usecases/get_employee_attendance_history_usecase.dart';
import '../features/admin/employee_section/presentation/controllers/attendance_history_controller.dart';
import '../features/admin/employee_section/presentation/controllers/attendance_report_controller.dart';
import '../features/admin/employee_section/presentation/views/attendance_report_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_point_categories_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_points_report_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_reward_rules_screen.dart';
import '../features/admin/employee_section/presentation/views/global_employee_points_screen.dart';
import '../core/services/banks_service.dart';
import '../features/admin/general_settings/presentation/controllers/banks_settings_controller.dart';
import '../features/admin/general_settings/presentation/views/attendance_settings_screen.dart';
import '../features/admin/general_settings/presentation/views/banks_settings_screen.dart';
import '../features/admin/general_settings/presentation/views/contact_categories_settings_screen.dart';
import '../features/admin/general_settings/presentation/views/general_settings_screen.dart';
import '../features/admin/attendance_devices/presentation/views/attendance_devices_screen.dart';
import '../features/admin/fingerprint_device_users/presentation/views/fingerprint_device_logs_screen.dart';
import '../features/admin/fingerprint_device_users/presentation/views/fingerprint_device_users_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_attendance_history_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_section_screen.dart';
import '../features/admin/employee_section/presentation/views/qr_history_screen.dart';
import '../features/admin/employee_section/presentation/views/points_rewards_guide_screen.dart';
import '../features/admin/employee_tasks/presentation/binding/employee_tasks_binding.dart';
import '../features/admin/employee_tasks/presentation/views/employee_tasks_screen.dart';
import '../features/admin/employee_tasks/presentation/views/task_details_entry_screen.dart';
import '../features/admin/financial_affairs/presentation/binding/assets_binding.dart';
import '../features/admin/financial_affairs/presentation/binding/expenses_binding.dart';
import '../features/admin/financial_affairs/presentation/binding/official_papers_binding.dart';
import '../features/admin/financial_affairs/presentation/views/assets_screens/add_new_assets_screen.dart';
import '../features/admin/financial_affairs/presentation/views/assets_screens/assets_log_screen.dart';
import '../features/admin/financial_affairs/presentation/views/assets_screens/assets_screen.dart';
import '../features/admin/financial_affairs/presentation/views/expenses_screens/add_expense_screen.dart';
import '../features/admin/financial_affairs/presentation/views/expenses_screens/destruction_products_screen.dart';
import '../features/admin/financial_affairs/presentation/views/expenses_screens/expenses_screen.dart';
import '../features/admin/financial_affairs/presentation/views/financial_affairs_screen.dart';
import '../features/admin/financial_affairs/presentation/views/official_papers_screens/file_box_screen.dart';
import '../features/admin/financial_affairs/presentation/views/official_papers_screens/files_screen.dart';
import '../features/admin/financial_affairs/presentation/views/official_papers_screens/official_papers_screen.dart';
import '../features/admin/financial_affairs/presentation/views/official_papers_screens/treasury_screen.dart';
import '../features/admin/general_data_list/presentation/binding/general_data_list_binding.dart';
import '../features/admin/general_data_list/presentation/views/add_new_customer_screen.dart';
import '../features/admin/general_data_list/presentation/views/general_data_list_screen.dart';
import '../features/admin/maintenance/presentation/binding/maintenance_binding.dart';
import '../features/admin/maintenance/presentation/views/maintenance_screen.dart';
import '../features/admin/maintenance/presentation/views/new_maintenance_screen.dart';
import '../features/admin/product_management/presentation/binding/product_management_binding.dart';
import '../features/admin/product_management/presentation/views/add_product_management_screen.dart';
import '../features/admin/product_management/presentation/views/product_management_screen.dart';
import '../features/admin/projects/presentation/binding/project_binding.dart';
import '../features/admin/projects/presentation/views/create_project_screen.dart';
import '../features/admin/projects/presentation/views/project_details_screeen.dart';
import '../features/admin/projects/presentation/views/project_screen.dart';
import '../features/admin/sales/presentation/binding/sales_binding.dart';
import '../features/admin/sales/presentation/views/new_cash_profit_screen.dart';
import '../features/admin/sales/presentation/views/instant_sale_product_picker_screen.dart';
import '../features/admin/sales/presentation/views/new_instant_sale_screen.dart';
import '../features/admin/sales/presentation/views/bill_details_screen.dart'
    as instant_sale_bill;
import '../features/admin/sales/presentation/views/sales_screen.dart';
import '../features/admin/special_tasks/presentation/binding/special_tasks_binding.dart';
import '../features/admin/special_tasks/presentation/views/special_task_details_screen.dart';
import '../features/admin/special_tasks/presentation/views/special_tasks_screen.dart';
import '../features/admin/stock/presentation/views/add_combination_screen.dart';
import '../features/admin/stock/presentation/views/add_edit_offer_package_screen.dart';
import '../features/admin/stock/presentation/views/offer_packages_screen.dart';
import '../features/admin/stock/presentation/binding/offer_packages_binding.dart';
import '../features/admin/stock/presentation/views/closeouts_screen.dart';
import '../features/admin/stock/presentation/views/edit_product_screen.dart';
import '../features/admin/stock/presentation/views/product_details_screen.dart';
import '../features/admin/categories/presentation/binding/category_management_binding.dart';
import '../features/admin/categories/presentation/views/category_management_screen.dart';
import '../features/admin/goals_section/presentation/binding/target_section_binding.dart';
import '../features/admin/goals_section/presentation/views/goals_section_screen.dart';
import '../features/admin/goals_section/presentation/views/add_new_goals_screen.dart';
import '../features/admin/goals_section/presentation/views/goals_details_screen.dart';
import '../features/auth/presentation/forget_password/binding/forget_password_binding.dart';
import '../features/auth/presentation/forget_password/views/forget_password_screen.dart';
import '../features/auth/presentation/login/binding/login_binding.dart';
import '../features/auth/presentation/sgin_up_verify/binding/sgin_up_verify_binding.dart';
import '../features/auth/presentation/sgin_up_verify/views/sgin_up_verify_screen.dart';
import '../features/auth/presentation/sign_up/binding/sign_up_binding.dart';
import '../features/auth/presentation/sign_up/views/sign_up_screen.dart';
import '../features/auth/presentation/forgot_password_otp/binding/forgot_password_otp_binding.dart';
import '../features/auth/presentation/forgot_password_otp/views/forgot_password_otp_screen.dart';
import '../features/auth/presentation/success/views/success_screen.dart';
import '../features/bottom_nav_bar/binding/binding.dart';
import '../features/bottom_nav_bar/views/bottom_nav_bar_screen.dart';
import '../features/common_feature/presentation/change_password/binding/change_password_binding.dart';
import '../features/common_feature/presentation/change_password/views/change_password_screen.dart';
import '../features/common_feature/presentation/contact_us/views/contact_us_screen.dart';
import '../features/common_feature/presentation/personal_details/binding/personal_details_binding.dart';
import '../features/common_feature/presentation/personal_details/views/personal_details_screen.dart';
import '../features/common_feature/presentation/user_profile/binding/profile_binding.dart';
import '../features/common_feature/presentation/user_profile/views/profile_screen.dart';
import '../features/employee/scan_qrcode/presentation/binding/qrcode_bideing.dart';
import '../features/employee/scan_qrcode/presentation/views/qr_code_screen.dart';
import '../features/home/binding/home_page_binding.dart';
import '../features/employee/my_orders/presentation/binding/my_orders_binding.dart';
import '../features/employee/my_orders/presentation/views/my_orders_screen.dart';
import 'app_routes.dart';

const _defaultTransition = Transition.noTransition;
// const _transitionZoom = Transition.zoom;
const _transitionFade = Transition.noTransition;
const _transitionFadeIn = Transition.noTransition;
const _transitionSize = Transition.noTransition;
const _transitionRightToLeft = Transition.noTransition;
const _transitionLeftToRight = Transition.noTransition;
const _transitionDownToUp = Transition.noTransition;
const _transitionUpToDown = Transition.noTransition;
const _transitionNo = Transition.noTransition;
// const _transitionCupertino = Transition.cupertino;
// const _transitionTopLevel = Transition.topLevel;
const _transitionCircularReveal = Transition.noTransition;
const _transitionCupertinoDialog = Transition.noTransition;

class AppPages {
  static final splashScreen = GetPage(
    name: AppRoutes.SPLASHSCREEN,
    page: () => const SplashScreen(),
    binding: SplashBinding(),
    transition: _transitionDownToUp,
  );

  static final List<GetPage> pages = [
    splashScreen,
    GetPage(
      name: AppRoutes.NOINTERNETSCREEN,
      page: () => const NoInternetScreen(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.CHOSELANGSCREEN,
      page: () => const ChoseLang(),
      transition: _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.ONBOARDINGSCREEN,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.LOGINORSIGNUPSCREEN,
      page: () => const LoginOrSignUpScreen(),
    ),
    GetPage(
      name: AppRoutes.SIGNUPSCREEN,
      page: () => const SignUpScreen(),
      binding: SignUpBinding(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.SIGNUPVERIFYSCREEN,
      page: () => const SginupVerifyScreen(),
      binding: SginupVerifyBinding(),
      transition: _transitionFade,
    ),
    GetPage(
      name: AppRoutes.SIGNUPOTPSCREEN,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordOtpBinding(),
      transition: _transitionLeftToRight,
    ),
    GetPage(
      name: AppRoutes.SIGNUPSUCCESSSCREEN,
      page: () => const SignUpSuccessScreen(),
      transition: _transitionFadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: AppRoutes.LOGINSCREEN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.FORGETPASSWORDSCREEN,
      page: () => const ForgetPasswordScreen(),
      binding: ForgetPasswordBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.BOTTOMNAVBARSCREEN,
      page: () => const BottomNavBarScreen(),
      binding: BottomNavBarBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.HOMEPAGESCREEN,
      page: () => const HomePageScreen(),
      binding: HomePageBinding(),
      transition: _defaultTransition,
    ),

    // Admin Dashboard
    GetPage(
      name: AppRoutes.ADMINDASHBOARDSCREEN,
      page: () => const AdminDashboardScreen(),
      binding: AdminDashboardBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.ADMINACTIVTILOGSCREEN,
      page: () => const AdminActivtiLogScreen(),
      binding: AdminDashboardBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.NOTIFICATIONCENTER,
      page: () => const AdminNotificationCenterScreen(),
      binding: AdminNotificationCenterBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEENOTIFICATIONCENTER,
      page: () => const EmployeeNotificationCenterScreen(),
      binding: EmployeeNotificationCenterBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEREMINDERSSCREEN,
      page: () => const EmployeeRemindersScreen(isAdmin: true),
      transition: _transitionFadeIn,
    ),

    // Employee Dashboard
    GetPage(
      name: AppRoutes.EMPLOYEEDASHBOARDSCREEN,
      page: () => const EmployeeDashbordScreen(),
      binding: EmployeeDashbordBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.MYEMPLOYEEREMINDERSSCREEN,
      page: () => const EmployeeRemindersScreen(isAdmin: false),
      transition: _transitionFadeIn,
    ),

    // مهام الموظفين
    GetPage(
      name: AppRoutes.EMPLOYEETASKSSCREEN,
      page: () => const EmployeeTasksScreen(),
      binding: EmployeeTasksBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.CREATETASKSCREEN,
      page: () => const CreateTaskEntryScreen(),
      binding: CreateTaskBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.TASKDETAILS,
      page: () => const TaskDetailsEntryScreen(),
      binding: EmployeeTasksBinding(),
      transition: _transitionFade,
    ),
    GetPage(
      name: AppRoutes.TASKRECURRENCE,
      page: () => const TaskRecurrenceScreen(),
      binding: CreateTaskBinding(),
      transition: _transitionFade,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEETASKPERFORMANCE,
      page: () => const EmployeeTaskPerformanceScreen(),
      transition: _transitionFade,
    ),

    // المهام الخاصة
    GetPage(
      name: AppRoutes.PRIVATETASKSSCREEN,
      page: () => const SpecialTasksScreen(),
      binding: SpecialTasksBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.SPECIALTASKDETAILSSCREEN,
      page: () => const SpecialTaskDetailsScreen(),
      binding: SpecialTasksBinding(),
      transition: _transitionFade,
    ),

    // قسم الموظفين
    GetPage(
      name: AppRoutes.EMPLOYEESECTIONSCREEN,
      page: () => const EmployeeSectionScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ADDNEWEMPLOYEESCREEN,
      page: () => const AddNewEmployeeScreen(),
      binding: EmployeeSectionBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEDETAILSSCREEN,
      page: () => const EmployeeDetailsScreen(),
      // binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ADDPENALTYANDREWARDSCREEN,
      page: () => const AddPenaltyAndRewardScreen(),
      binding: EmployeeSectionBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.POINTSTABLE,
      page: () => const PointsRewardsGuideScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.ACTIVITYLOGSCREEN,
      page: () => const ActivityLogScreen(),
      // binding: EmployeeSectionBinding(),
      transition: _transitionCircularReveal,
    ),
    GetPage(
      name: AppRoutes.FULLSCREENQRSCANNER,
      page: () => const FullScreenQRScanner(),
      binding: QrCodeBinding(),
      transition: _transitionCircularReveal,
    ),
    GetPage(
      name: AppRoutes.QRHISTORYSCREEN,
      page: () => const QrHistoryScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEATTENDANCEHISTORY,
      page: () => const EmployeeAttendanceHistoryScreen(),
      binding: BindingsBuilder(() {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        Get.lazyPut(
          () => AttendanceHistoryController(
            employeeId: args['employeeId'] as String? ?? '',
            employeeName: args['employeeName'] as String? ?? '',
            getHistory: GetEmployeeAttendanceHistoryUsecase(
              employeeRepository: Get.find<EmployeeImplement>(),
            ),
          ),
        );
      }),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.MYATTENDANCEHISTORY,
      page: () => const MyAttendanceHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => MyAttendanceHistoryController(
            getMyAttendanceHistoryUsecase: GetMyAttendanceHistoryUsecase(
              employeeDashbordRepository: Get.find<EmployeeDashbordImplement>(),
            ),
          ),
        );
      }),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ATTENDANCEREPORTSCREEN,
      page: () => const AttendanceReportScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => AttendanceReportController(
            getReport: GetAttendanceReportUsecase(
              employeeRepository: Get.find<EmployeeImplement>(),
            ),
          ),
        );
      }),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEREWARDRULESSCREEN,
      page: () => const EmployeeRewardRulesScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEPOINTCATEGORIESSCREEN,
      page: () => const EmployeePointCategoriesScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.GLOBALEMPLOYEEPOINTSSCREEN,
      page: () => const GlobalEmployeePointsScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.EMPLOYEEPOINTSREPORTSCREEN,
      page: () => const EmployeePointsReportScreen(),
      binding: EmployeeSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.GENERALSETTINGSSCREEN,
      page: () => const GeneralSettingsScreen(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.BANKSSETTINGSSCREEN,
      page: () => const BanksSettingsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<BanksSettingsController>()) {
          Get.lazyPut(() => BanksSettingsController());
        }
        if (!Get.isRegistered<BanksService>()) {
          Get.put(BanksService());
        }
      }),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.CONTACTCATEGORIESSETTINGSSCREEN,
      page: () => const ContactCategoriesSettingsScreen(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ATTENDANCESETTINGSSCREEN,
      page: () => const AttendanceSettingsScreen(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ATTENDANCEDEVICESSCREEN,
      page: () => const AttendanceDevicesScreen(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.FINGERPRINTDEVICEUSERSSCREEN,
      page: () => const FingerprintDeviceUsersScreen(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.FINGERPRINTDEVICELOGSSCREEN,
      page: () => const FingerprintDeviceLogsScreen(),
      transition: _transitionFadeIn,
    ),

    // قسم ادارة المشاريع
    GetPage(
      name: AppRoutes.PROJECTMANAGEMENTSCREEN,
      page: () => const ProjectScreen(),
      binding: ProjectBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.PROJECTDETAILSSCREEN,
      page: () => const ProjectDetailsScreeen(),
      // binding: ,
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.CREATEPROJECTSCREEN,
      page: () => const CreateProjectScreen(),
      // binding: ,
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // قسم صناعة الاهداف
    GetPage(
      name: AppRoutes.TARGETSECTIONSCREEN,
      page: () => const GoalsSectionScreen(),
      binding: TargetSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.TARGETDETAILSSCREEN,
      page: () => const GoalsDetailsScreen(),
      // binding: ,
      transition: _transitionFade,
    ),
    GetPage(
      name: AppRoutes.ADDNEWTARGETSCREEN,
      page: () => const AddNewGoalScreen(),
      binding: TargetSectionBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // قسم المتابعة
    GetPage(
      name: AppRoutes.CURRENTFOLLOWUPSCREEN,
      page: () => const CurrentFollowUpScreen(),
      binding: FollowUpBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ADDFOLLOWUPSCREEN,
      page: () => const AddNewFollowUpScreen(),
      // binding:
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // قائمة البيانات العامة
    GetPage(
      name: AppRoutes.GENERALDATALISTSCREEN,
      page: () => const GeneralDataListScreen(),
      binding: GeneralDataListBinding(),
      transition: _transitionFadeIn,
    ),
    // GetPage(
    //   name: AppRoutes.GLOBALCUSTOMERDATASCREEN,
    //   page: () => const GlobalCustomerDataScreen(),
    //   // binding:
    //   transition: _transitionFade,
    // ),
    GetPage(
      name: AppRoutes.ADDNEWCUSTOMERSCREEN,
      page: () => const AddNewCustomerScreen(),
      binding: GeneralDataListBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // إنشاء الصناديق
    GetPage(
      name: AppRoutes.DEBTSSCREEN,
      page: () => const DebtsScreen(),
      binding: DebtsBinding(),
      transition: _transitionFadeIn,
    ),

    // المبيعات
    GetPage(
      name: AppRoutes.SALESSCREEN,
      page: () => const SalesScreen(),
      binding: SalesBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.INSTANTSALEPRODUCTPICKER,
      page: () => const InstantSaleProductPickerScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.NEWINSTANTSALESCREEN,
      page: () => const NewInstantSaleScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.INSTANTSALEBILLDETAILSSCREEN,
      page: () => const instant_sale_bill.BillDetailsScreen(),
      binding: SalesBinding(),
      transition: _transitionSize,
    ),
    GetPage(
      name: AppRoutes.NEWCASHPROFITSCREEN,
      page: () => const NewCashProfitScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // Checks
    GetPage(
      name: AppRoutes.CHECKSSCREEN,
      page: () => const ChecksScreen(),
      binding: ChecksBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.OUTGOINGCHECKSSCREEN,
      page: () => const OutgoingChecksScreen(),
      binding: ChecksBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.INCOMINGCHECKSSCREEN,
      page: () => const IncomingChecksScreen(),
      binding: ChecksBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.NEWCHECKSCREEN,
      page: () => const NewCheckScreen(),
      binding: ChecksBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.CHECKNOTIFICATIONRULESSCREEN,
      page: () => const CheckNotificationRulesScreen(),
      binding: ChecksBinding(),
      transition: _transitionDownToUp,
    ),

    // Boxes
    GetPage(
      name: AppRoutes.BOXESSCREEN,
      page: () => const BoxesScreen(),
      binding: BoxesBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.CREATEBOXESSCREEN,
      binding: BoxesBinding(),
      page: () => const CreateBoxesScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.EDITBOXESSCREEN,
      page: () => const EditBoxesScreen(),
      transition: _transitionCircularReveal,
    ),

    // Maintenance Screen
    GetPage(
      name: AppRoutes.MAINTENANCESCREEN,
      page: () => const MaintenanceScreen(),
      binding: MaintenanceBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.NEWMAINTENANCESCREEN,
      page: () => const NewMaintenanceScreen(),
      binding: MaintenanceBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // Stock
    GetPage(
      name: AppRoutes.STOCKSCREEN,
      page: () => const StockScreen(),
      binding: StockBinding(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.PRODUCTDETAILSSCREEN,
      page: () => const ProductDetailsScreen(),
      binding: StockBinding(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.EDITPRODUCTSCREEN,
      page: () => const EditProductScreen(),
      binding: StockBinding(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.CLOSEOUTSSCREEN,
      page: () => const CloseoutsScreen(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.ADDCOMBINATIONSCREEN,
      page: () => const AddCombinationScreen(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.OFFERPACKAGESSCREEN,
      page: () => const OfferPackagesScreen(),
      binding: OfferPackagesBinding(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.ADDEDITOFFERPACKAGESCREEN,
      page: () => const AddEditOfferPackageScreen(),
      binding: OfferPackagesBinding(),
      transition: _transitionNo,
      transitionDuration: Duration.zero,
    ),

    // Buying
    GetPage(
      name: AppRoutes.BUYINGSCREEN,
      page: () => const BuyingScreen(),
      binding: BuyingBinding(),
      transition: _transitionFadeIn,
    ),
    // Bills
    GetPage(
      name: AppRoutes.BILLSSCREEN,
      page: () => const BillsScreen(),
      binding: BuyingBinding(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.ADDNEWBILLSCREEN,
      page: () => const AddNewBillScreen(),
      binding: BuyingBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.BILLDETAILSSCREEN,
      page: () => const BillDetailsScreen(),
      binding: BuyingBinding(),
      transition: _transitionSize,
    ),
    // Purchases
    GetPage(
      name: AppRoutes.PURCHASEORDERSSCREEN,
      page: () => const PurchaseOrdersScreen(),
      binding: BuyingBinding(),
      transition: _transitionFadeIn,
    ),
    // Return Purchases
    GetPage(
      name: AppRoutes.RETURNPURCHASESSCREEN,
      page: () => const ReturnPurchasesScreen(),
      binding: BuyingBinding(),
      transition: _transitionDownToUp,
    ),

    // Financial Affairs
    GetPage(
      name: AppRoutes.FINANCIALAFFAIRSSCREEN,
      page: () => const FinancialAffairsScreen(),
      binding: AssetsBinding(),
      transition: _transitionFadeIn,
    ),
    // Assets
    GetPage(
      name: AppRoutes.ASSETSSCREEN,
      page: () => const AssetsScreen(),
      binding: AssetsBinding(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.ASSETLOGSCREEN,
      page: () => const AssetsLogScreen(),
      binding: AssetsBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.ADDNEWASSETSCREEN,
      page: () => const AddNewAssetsScreen(),
      binding: AssetsBinding(),
      transition: _transitionSize,
    ),
    // Expenses
    GetPage(
      name: AppRoutes.THEEXPENSESSCREEN,
      page: () => const ExpensesScreen(),
      binding: ExpensesBinding(),
      transition: _transitionCupertinoDialog,
    ),
    GetPage(
      name: AppRoutes.DESTRUCTIONPRODUCTSSCREEN,
      page: () => const DestructionProductsScreen(),
      binding: ExpensesBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.ADDEXPENSESCREEN,
      page: () => const AddExpenseScreen(),
      binding: ExpensesBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    // official papers
    GetPage(
      name: AppRoutes.OFFICIALPAPERSSCREEN,
      page: () => const OfficialPapersScreen(),
      binding: OfficialPapersBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.SAFESSCREEN,
      page: () => const TreasuryScreen(),
      binding: OfficialPapersBinding(),
      transition: _transitionUpToDown,
    ),
    GetPage(
      name: AppRoutes.FILEBOXSCREEN,
      page: () => const FileBoxScreen(),
      binding: OfficialPapersBinding(),
      transition: _transitionCupertinoDialog,
    ),
    GetPage(
      name: AppRoutes.FILESSCREEN,
      page: () => const FilesScreen(),
      binding: OfficialPapersBinding(),
      transition: _transitionSize,
    ),

    // PRODUCT MANAGEMENT
    GetPage(
      name: AppRoutes.PRODUCTMANAGEMENTSCREEN,
      page: () => const ProductManagementScreen(),
      binding: ProductManagementBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ADDPRODUCTMANAGEMENTSCREEN,
      page: () => const AddProductManagementScreen(),
      binding: ProductManagementBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // Category Management
    GetPage(
      name: AppRoutes.CATEGORYMANAGEMENTSCREEN,
      page: () => const CategoryManagementScreen(),
      binding: CategoryManagementBinding(),
      transition: _transitionFadeIn,
    ),

    // Counters
    GetPage(
      name: AppRoutes.COUNTERSSCREEN,
      page: () => const CountersScreen(),
      binding: CountersBinding(),
      transition: _transitionDownToUp,
    ),

    // Profile Screen
    GetPage(
      name: AppRoutes.PROFILESCREEN,
      page: () => const ProfileScreen(),
      binding: ProfileScreenBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.PERSONALDETAILSSCREEN,
      page: () => const PersonalDetailsScreen(),
      binding: PersonalDetailsBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.CHANGEPASSWORDSCREEN,
      page: () => const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.MYORDERSSCREEN,
      page: () => const MyOrdersScreen(),
      binding: MyOrdersBinding(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.CONTACTUSSCREEN,
      page: () => const ContactUsScreen(),
      transition: _transitionCircularReveal,
    ),
  ];
}
