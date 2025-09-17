import 'dart:ui';

import 'package:get/get.dart';

import 'package:doctorbike/features/App_entr/on_boarding/widgets/login_or_sign_up.dart';
import 'package:doctorbike/features/admin/stock/presentation/binding/stock_binding.dart';
import 'package:doctorbike/features/admin/stock/presentation/views/stock_screen.dart';
import 'package:doctorbike/features/auth/presentation/login/views/login_screen.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/binding/employee_dashbord_binding.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/views/employee_dashbord_screen.dart';
import 'package:doctorbike/features/home/views/home_page_screen.dart';

import '../features/App_entr/no_internet/view/no_internet_screen.dart';
import '../features/App_entr/on_boarding/binding/onboarding_binding.dart';
import '../features/App_entr/on_boarding/view/on_boarding_screen.dart';
import '../features/App_entr/on_boarding/widgets/chose_lang.dart';
import '../features/App_entr/splash/binding/splash_binding.dart';
import '../features/App_entr/splash/view/splash_screen.dart';
import '../features/admin/--/presentation/current_follow_up/binding/current_follow_up_binding.dart';
import '../features/admin/--/presentation/current_follow_up/views/current_follow_up_screen.dart';
import '../features/admin/--/presentation/current_follow_up/widgets/add_customer_follow_up.dart';
import '../features/admin/--/presentation/current_follow_up/widgets/add_new_follow_customer.dart';
import '../features/admin/admin_dashbord/presentation/binding/admin_dashboard_binding.dart';
import '../features/admin/admin_dashbord/presentation/views/admin_activti_log_screen.dart';
import '../features/admin/admin_dashbord/presentation/views/admin_dashboard_screen.dart';
import '../features/admin/boxes/presentation/binding/boxes_binding.dart';
import '../features/admin/boxes/presentation/views/boxes_screen.dart';
import '../features/admin/boxes/presentation/views/create_boxes_screen.dart';
import '../features/admin/boxes/presentation/views/edit_boxes_screen.dart';
import '../features/admin/buying/presentation/binding/buying_binding.dart';
import '../features/admin/buying/presentation/views/bills_screen.dart';
import '../features/admin/buying/presentation/views/buying_screen.dart';
import '../features/admin/checks/presentation/binding/checks_binding.dart';
import '../features/admin/checks/presentation/views/checks_screen.dart';
import '../features/admin/checks/presentation/views/incoming_checks_screen.dart';
import '../features/admin/checks/presentation/views/new_check_screen.dart';
import '../features/admin/checks/presentation/views/outgoing_checks_screen.dart';
import '../features/admin/counters/presentation/binding/counters_binding.dart';
import '../features/admin/counters/presentation/views/counters_screen.dart';
import '../features/admin/create_tasks/presentation/binding/create_task_binding.dart';
import '../features/admin/create_tasks/presentation/views/create_task_screen.dart';
import '../features/admin/debts/presentation/binding/debts_binding.dart';
import '../features/admin/debts/presentation/views/debts_screen.dart';
import '../features/admin/employee_section/presentation/binding/employee_section_binding.dart';
import '../features/admin/employee_section/presentation/views/activity_log_screen.dart';
import '../features/admin/employee_section/presentation/views/add_new_employee_screen.dart';
import '../features/admin/employee_section/presentation/views/add_penalty_and_reward.dart';
import '../features/admin/employee_section/presentation/views/employee_details_screen.dart';
import '../features/admin/employee_section/presentation/views/employee_section_screen.dart';
import '../features/admin/employee_section/presentation/views/working_bonuses_screen.dart';
import '../features/admin/employee_tasks/presentation/binding/employee_tasks_binding.dart';
import '../features/admin/employee_tasks/presentation/views/employee_tasks_screen.dart';
import '../features/admin/employee_tasks/presentation/views/task_details_screen.dart';
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
import '../features/admin/financial_affairs/presentation/views/official_papers_screens/safes_screen.dart';
import '../features/admin/general_data_list/presentation/binding/general_data_list_binding.dart';
import '../features/admin/general_data_list/presentation/views/add_new_customer_screen.dart';
import '../features/admin/general_data_list/presentation/views/general_data_list_screen.dart';
import '../features/admin/maintenance/presentation/binding/maintenance_binding.dart';
import '../features/admin/maintenance/presentation/views/maintenance_screen.dart';
import '../features/admin/maintenance/presentation/views/new_maintenance_screen.dart';
import '../features/admin/projects/presentation/binding/project_binding.dart';
import '../features/admin/projects/presentation/views/create_project_screen.dart';
import '../features/admin/projects/presentation/views/project_details_screeen.dart';
import '../features/admin/projects/presentation/views/project_screen.dart';
import '../features/admin/sales/presentation/binding/sales_binding.dart';
import '../features/admin/sales/presentation/views/new_cash_profit_screen.dart';
import '../features/admin/sales/presentation/views/new_instant_sale_screen.dart';
import '../features/admin/sales/presentation/views/sales_screen.dart';
import '../features/admin/special_tasks/presentation/binding/special_tasks_binding.dart';
import '../features/admin/special_tasks/presentation/views/special_task_details_screen.dart';
import '../features/admin/special_tasks/presentation/views/special_tasks_screen.dart';
import '../features/admin/stock/presentation/views/add_combination_screen.dart';
import '../features/admin/stock/presentation/views/closeouts_screen.dart';
import '../features/admin/stock/presentation/views/edit_product_screen.dart';
import '../features/admin/stock/presentation/views/product_details_screen.dart';
import '../features/admin/target_section/presentation/binding/target_section_binding.dart';
import '../features/admin/target_section/presentation/views/target_section_screen.dart';
import '../features/admin/target_section/presentation/widgets/add_new_target/add_new_target_screen.dart';
import '../features/admin/target_section/presentation/widgets/target_details/target_details_screen.dart';
import '../features/auth/presentation/login/binding/login_binding.dart';
import '../features/auth/presentation/sgin_up_verify/binding/sgin_up_verify_binding.dart';
import '../features/auth/presentation/sgin_up_verify/views/sgin_up_verify_screen.dart';
import '../features/auth/presentation/sign_up/binding/sign_up_binding.dart';
import '../features/auth/presentation/sign_up/views/sign_up_screen.dart';
import '../features/auth/presentation/sign_up_otp/binding/sign_up_otp_binding.dart';
import '../features/auth/presentation/sign_up_otp/views/sign_up_otp_screen.dart';
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
import '../features/my_orders/binding/my_orders_binding.dart';
import '../features/my_orders/views/my_orders_screen.dart';
import 'app_routes.dart';

const _defaultTransition = Transition.native;
// const _transitionZoom = Transition.zoom;
const _transitionFade = Transition.fade;
const _transitionFadeIn = Transition.fadeIn;
const _transitionSize = Transition.size;
const _transitionRightToLeft = Transition.rightToLeft;
const _transitionLeftToRight = Transition.leftToRight;
const _transitionDownToUp = Transition.downToUp;
const _transitionUpToDown = Transition.upToDown;
// const _transitionCupertino = Transition.cupertino;
// const _transitionTopLevel = Transition.topLevel;
const _transitionCircularReveal = Transition.circularReveal;
const _transitionCupertinoDialog = Transition.cupertinoDialog;

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
      page: () => const SignUpOtpScreen(),
      binding: SignUpOtpBinding(),
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

    // Employee Dashboard
    GetPage(
      name: AppRoutes.EMPLOYEEDASHBOARDSCREEN,
      page: () => const EmployeeDashbordScreen(),
      binding: EmployeeDashbordBinding(),
      transition: _transitionDownToUp,
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
      page: () => const CreateTaskScreen(),
      binding: CreateTaskBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.TASKDETAILS,
      page: () => const TaskDetailsScreen(),
      binding: EmployeeTasksBinding(),
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
      page: () => const PointsTable(),
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
      page: () => const TargetSectionScreen(),
      binding: TargetSectionBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.TARGETDETAILSSCREEN,
      page: () => const TargetDetailsScreen(),
      // binding: ,
      transition: _transitionFade,
    ),
    GetPage(
      name: AppRoutes.ADDNEWTARGETSCREEN,
      page: () => const AddNewTargetScreen(),
      // binding: ,
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    // قسم المتابعة
    GetPage(
      name: AppRoutes.CURRENTFOLLOWUPSCREEN,
      page: () => const CurrentFollowUpScreen(),
      binding: CurrentFollowUpBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.ADDCUSTOMERFOLLOWUPSCREEN,
      page: () => const AddCustomerFollowUpScreen(),
      // binding:
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.ADDNEWFOLLOWCUSTOMERSCREEN,
      page: () => const AddNewFollowCustomerScreen(),
      // binding:
      transition: _transitionFade,
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
      name: AppRoutes.NEWINSTANTSALESCREEN,
      page: () => const NewInstantSaleScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
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
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.INCOMINGCHECKSSCREEN,
      page: () => const IncomingChecksScreen(),
      transition: _transitionDownToUp,
    ),
    GetPage(
      name: AppRoutes.NEWCHECKSCREEN,
      page: () => const NewCheckScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
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
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.PRODUCTDETAILSSCREEN,
      page: () => const ProductDetailsScreen(),
      binding: StockBinding(),
      transition: _transitionSize,
    ),
    GetPage(
      name: AppRoutes.EDITPRODUCTSCREEN,
      page: () => const EditProductScreen(),
      binding: StockBinding(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.CLOSEOUTSSCREEN,
      page: () => const CloseoutsScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),
    GetPage(
      name: AppRoutes.ADDCOMBINATIONSCREEN,
      page: () => const AddCombinationScreen(),
      transition: Get.locale == const Locale('ar')
          ? _transitionLeftToRight
          : _transitionRightToLeft,
    ),

    // Buying
    GetPage(
      name: AppRoutes.BUYINGSCREEN,
      page: () => const BuyingScreen(),
      binding: BuyingBinding(),
      transition: _transitionFadeIn,
    ),
    GetPage(
      name: AppRoutes.BILLSSCREEN,
      page: () => const BillsScreen(),
      binding: BuyingBinding(),
      transition: _transitionFadeIn,
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
      page: () => const SafesScreen(),
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
