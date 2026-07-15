// ignore_for_file: constant_identifier_names

class AppRoutes {
  static const SPLASHSCREEN = '/';
  static const NOINTERNETSCREEN = '/nointernetscreen';
  static const CHOSELANGSCREEN = '/choselangscreen';
  static const ONBOARDINGSCREEN = '/onboardingscreen';
  static const LOGINORSIGNUPSCREEN = '/loginorsignupscreen';
  static const SIGNUPSCREEN = '/signupscreen';
  static const SIGNUPVERIFYSCREEN = '/signupverifyscreen';
  static const SIGNUPOTPSCREEN = '/signupotpscreen';
  static const SIGNUPSUCCESSSCREEN = '/signupsuccessscreen';
  static const LOGINSCREEN = '/loginscreen';
  static const BOTTOMNAVBARSCREEN = '/bottomnavbarscreen';
  static const HOMEPAGESCREEN = '/homepagescreen';
  static const FORGETPASSWORDSCREEN = '/ForgetPasswordScreen';

  // Admin Dashboard
  static const ADMINDASHBOARDSCREEN = '/dashboardscreen';
  static const EMPLOYEEDASHBOARDSCREEN = '/EmployeeDashbordScreen';
  static const EMPLOYEETASKSSCREEN = '/employeetasksscreen';
  static const EMPLOYEEREMINDERSSCREEN = '/employeeremindersscreen';
  static const MYEMPLOYEEREMINDERSSCREEN = '/myemployeeremindersscreen';
  static const EMPLOYEESUGGESTIONSSCREEN = '/employeesuggestionsscreen';
  static const MYEMPLOYEESUGGESTIONSSCREEN = '/myemployeesuggestionsscreen';
  static const CREATETASKSCREEN = '/createtaskscreen';
  static const TASKDETAILS = '/taskdetails';
  static const TASKRECURRENCE = '/taskrecurrence';
  static const EMPLOYEETASKPERFORMANCE = '/employeetaskperformance';
  static const PRIVATETASKSSCREEN = '/privatetasksscreen';
  static const EMPLOYEESECTIONSCREEN = '/employeesectionscreen';
  static const ADDNEWEMPLOYEESCREEN = '/AddNewEmployeeScreen';
  static const ADDEDITADMINSCREEN = '/AddEditAdminScreen';
  static const CURRENTFOLLOWUPSCREEN = '/CurrentFollowUpScreen';
  static const ADDFOLLOWUPSCREEN = '/AddFollowUpScreen';
  static const PROJECTMANAGEMENTSCREEN = '/ProjectManagementScreen';
  static const PROJECTDETAILSSCREEN = '/ProjectDetailsScreeen';
  static const CREATEPROJECTSCREEN = '/CreateProjectScreen';
  static const GENERALDATALISTSCREEN = '/GeneralDataListScreen';
  static const GLOBALCUSTOMERDATASCREEN = '/GlobalCustomerDataScreen';
  static const ADDNEWCUSTOMERSCREEN = '/AddNewCustomerScreen';
  static const DEBTSSCREEN = '/DebtsScreen';
  static const ADMINACTIVTILOGSCREEN = '/AdminActivtiLogScreen';
  static const NOTIFICATIONCENTER = '/AdminNotificationCenter';
  static const EMPLOYEENOTIFICATIONCENTER = '/EmployeeNotificationCenter';
  static const WHATSAPPCENTER = '/WhatsAppCenter';
  static const WHATSAPPCONVERSATION = '/WhatsAppConversation/:id';
  static const METACATALOGSYNC = '/MetaCatalogSync';

  // EMPLOYEE TASKS SCREEN
  static const EMPLOYEEDETAILSSCREEN = '/EmployeeDetailsScreen';
  static const ADDPENALTYANDREWARDSCREEN = '/AddPenaltyAndRewardScreen';
  static const POINTSTABLE = '/PointsTable';
  static const ACTIVITYLOGSCREEN = '/ActivityLogScreen';
  static const FULLSCREENQRSCANNER = '/FullScreenQRScanner';
  static const QRHISTORYSCREEN = '/QrHistoryScreen';
  static const EMPLOYEEATTENDANCEHISTORY = '/EmployeeAttendanceHistory';
  static const MYATTENDANCEHISTORY = '/MyAttendanceHistory';
  static const ATTENDANCEREPORTSCREEN = '/AttendanceReportScreen';

  // Boxes Screen
  static const BOXESSCREEN = '/BoxesScreen';
  static const DAILYBOXESSCREEN = '/DailyBoxesScreen';
  static const CREATEBOXESSCREEN = '/CreateBoxesScreen';
  static const EDITBOXESSCREEN = '/EditBoxesScreen';

  // Maintenance Screen
  static const MAINTENANCESCREEN = '/MaintenancesScreen';
  static const NEWMAINTENANCESCREEN = '/NewMaintenanceScreen';

  // Sales
  static const SALESSCREEN = '/SalesScreen';
  static const SALESORDERDETAILSCREEN = '/SalesOrderDetailScreen';
  static const NEWSALESORDERSCREEN = '/NewSalesOrderScreen';
  static const SALESORDERCHECKOUTSCREEN = '/SalesOrderCheckoutScreen';
  static const INSTANTSALEPRODUCTPICKER = '/InstantSaleProductPicker';
  static const NEWINSTANTSALESCREEN = '/NewInstantSaleScreen';
  static const ADJUSTMENTSALEPRODUCTPICKER = '/AdjustmentSaleProductPicker';
  static const NEWADJUSTMENTSALESCREEN = '/NewAdjustmentSaleScreen';
  static const NEWCASHPROFITSCREEN = '/NewCashProfitScreen';
  static const SUSPENDEDINVOICESSCREEN = '/SuspendedInvoicesScreen';

  // Checks
  static const CHECKSSCREEN = '/ChecksScreen';
  static const OUTGOINGCHECKSSCREEN = '/OutgoingChecksScreen';
  static const INCOMINGCHECKSSCREEN = '/IncomingChecksScreen';
  static const NEWCHECKSCREEN = '/NewCheckScreen';
  static const EDITCHECKSCREEN = '/EditCheckScreen';
  static const CHECKNOTIFICATIONRULESSCREEN = '/CheckNotificationRulesScreen';

  // Profile Screen
  static const PROFILESCREEN = '/profilescreen';
  static const PERSONALDETAILSSCREEN = '/personaldetailsscreen';
  static const CHANGEPASSWORDSCREEN = '/changepasswordscreen';
  static const MYORDERSSCREEN = '/myordersscreen';
  static const CONTACTUSSCREEN = '/contactus';

  // Special Tasks
  static const SPECIALTASKDETAILSSCREEN = '/SpecialTaskDetailsScreen';

  // Stock
  static const STOCKSCREEN = '/StockScreen';
  static const PRODUCTDETAILSSCREEN = '/ProductDetailsScreen';
  static const PRODUCTSTOCKMOVEMENTSSCREEN = '/ProductStockMovementsScreen';
  static const EDITPRODUCTSCREEN = '/EditProductScreen';
  static const CLOSEOUTSSCREEN = '/CloseoutsScreen';
  static const ADDCOMBINATIONSCREEN = '/AddCombinationScreen';
  static const OFFERPACKAGESSCREEN = '/OfferPackagesScreen';
  static const ADDEDITOFFERPACKAGESCREEN = '/AddEditOfferPackageScreen';

  // Financial Affairs
  static const FINANCIALAFFAIRSSCREEN = '/FinancialAffairsScreen';
  static const ASSETSSCREEN = '/AssetsScreen';
  static const THEEXPENSESSCREEN = '/TheExpensesScreen';
  static const OFFICIALPAPERSSCREEN = '/OfficialPapersScreen';

  static const ASSETLOGSCREEN = '/AssetsLog';
  static const ADDNEWASSETSCREEN = '/AddNewAssetsScreen';
  static const DESTRUCTIONPRODUCTSSCREEN = '/DestructionProductsScreen';
  static const ADDEXPENSESCREEN = '/AddExpenseScreen';
  static const SAFESSCREEN = '/SafesScreen';
  static const FILEBOXSCREEN = '/FileBoxScreen';
  static const FILESSCREEN = '/FilesScreen';

  // Counters
  static const COUNTERSSCREEN = '/CountersScreen';

  // Goals
  static const TARGETSECTIONSCREEN = '/TargetSectionScreen';
  static const TARGETDETAILSSCREEN = '/TargetDetailsScreen';
  static const ADDNEWTARGETSCREEN = '/AddNewTargetScreen';

  // Buying
  static const BUYINGSCREEN = '/BuyingScreen';
  static const BILLSSCREEN = '/BillsScreen';
  // bill
  static const ADDNEWBILLSCREEN = '/AddNewBillScreen';
  static const BILLDETAILSSCREEN = '/BillDetailsScreen';

  /// تفاصيل فاتورة البيع الفوري (منفصل عن فواتير المشتريات).
  static const INSTANTSALEBILLDETAILSSCREEN = '/InstantSaleBillDetailsScreen';
  static const SALESDAILYCLOSESCREEN = '/SalesDailyCloseScreen';
  static const SALESDAILYADMINSCREEN = '/SalesDailyAdminScreen';
  static const SALESDAILYHISTORYSCREEN = '/SalesDailyHistoryScreen';
  static const SALESDAILYSESSIONDETAILSCREEN = '/SalesDailySessionDetailScreen';
  // purchase orders
  static const PURCHASEORDERSSCREEN = '/PurchaseOrdersScreen';
  // return purchases
  static const RETURNPURCHASESSCREEN = '/ReturnPurchasesScreen';

  // Product Management
  static const PRODUCTMANAGEMENTSCREEN = '/ProductManagementScreen';
  static const ADDPRODUCTMANAGEMENTSCREEN = '/AddProductManagementScreen';

  // Category Management
  static const CATEGORYMANAGEMENTSCREEN = '/CategoryManagementScreen';

  // Employee Points & Rewards
  static const EMPLOYEEREWARDRULESSCREEN = '/EmployeeRewardRulesScreen';
  static const EMPLOYEEPOINTCATEGORIESSCREEN = '/EmployeePointCategoriesScreen';
  static const GLOBALEMPLOYEEPOINTSSCREEN = '/GlobalEmployeePointsScreen';
  static const EMPLOYEEPOINTSREPORTSCREEN = '/EmployeePointsReportScreen';

  // General Settings (admin)
  static const GENERALSETTINGSSCREEN = '/GeneralSettingsScreen';
  static const STOCKINVENTORYSETTINGSSCREEN = '/StockInventorySettingsScreen';
  static const PRODUCTSIZEOPTIONSSETTINGSSCREEN =
      '/ProductSizeOptionsSettingsScreen';
  static const STORESECTIONSSETTINGSSCREEN = '/StoreSectionsSettingsScreen';
  static const BANKSSETTINGSSCREEN = '/BanksSettingsScreen';
  static const CONTACTCATEGORIESSETTINGSSCREEN =
      '/ContactCategoriesSettingsScreen';

  // Attendance / Fingerprint (admin)
  static const ATTENDANCEDEVICESSCREEN = '/AttendanceDevicesScreen';
  static const ATTENDANCESETTINGSSCREEN = '/AttendanceSettingsScreen';
  static const FINGERPRINTDEVICEUSERSSCREEN = '/FingerprintDeviceUsersScreen';
  static const FINGERPRINTDEVICELOGSSCREEN = '/FingerprintDeviceLogsScreen';
}
