// ignore_for_file: constant_identifier_names

import '../../services/initial_bindings.dart';

class EndPoints {
  static String baserUrl =
      startApp.value ? "http://doctorbike.mj-sall.com/api/" : '';
  static const String baserUrlForImage = "http://doctorbike.mj-sall.com/";

  static const String register = 'register';
  static const String sendCode = 'send/code';
  static const String verifyCode = 'verify/code';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String changePassword = 'change/password';
  static const String updateProfile = 'update/profile';
  static const String me = 'me';

  // employee Dashboard
  static const String employeeHomeData = 'employee/home/data';
  static const String changeEmployeeTaskToCompleted =
      'change/employee/task/to/completed';
  static const String changeSubEmployeeTaskToCompleted =
      'change/sub/employee/task/to/completed';

  static const String addOvertimeOrder = 'employee/add/overtime/order';
  static const String addLoanOrder = 'employee/add/loan/order';

  static const String getMyOrders = 'employee/orders';
  static const String getAttendanceDetails = 'get/attendance/details';

  // admin dashboard
  static const String adminLogs = 'all/logs';
  static const String adminHomeData = 'admin/home/page/data';

  // debts section
  static const String totalDebtsWeOwe = 'total/debts/we/owe';
  static const String totalDebtsOwedToUs = 'total/debts/owed/to/us';
  static const String getDebtsOwedToUs = 'get/debts/owed/to/us';
  static const String getDebtsWeOwe = 'get/debts/we/owe';
  static const String personDebts = 'person/debts';
  static const String addDebt = 'add/debt';
  static const String getDebtsReports = 'get/debts/reports';

  // employees section
  static const String createEmployee = 'create/employee';
  static const String addPointsToEmployee = 'add/points/to/employee';
  static const String minusPointsFromEmployee = 'minus/points/from/employee';
  static const String paySalaryToEmployee = 'pay/employee/salary';
  static const String employees = 'employees';
  static const String workingTimes = 'working/times';
  static const String financialDues = 'financial/dues';
  static const String employeeFinancialDetails =
      'show/employee/financial/details';
  static const String employeePermissions = 'employee/permissions';
  static const String qrGeneration = 'qr-generation';
  static const String editEmployee = 'edit/employee';
  static const String qrScan = 'qr-scan';
  static const String overtimeOrders = 'employee/overtime/orders';
  static const String loanOrders = 'employee/loan/orders';
  static const String rejectEmployeeOrder = 'reject/employee/order';
  static const String approveEmployeeLoanOrder = 'approve/employee/loan/order';
  static const String approveEmployeeOvertimeOrder =
      'approve/employee/overtime/order';
  static const String employeeLogs = 'employee/logs';
  static const String cancelLog = 'cancel/log';
  static const String employeeFinancialDataReport =
      'get/employee/financial/data/report';

  // tasks section
  static const String createEmployeeTask = 'create/employee/task';
  static const String editEmployeeTask = 'edit/employee/task';

  static const String createSpecialTask = 'create/special/task';

  static const String getEmployeeTasks = 'employee/ongoing/tasks';
  static const String getCompletedTasks = 'employee/completed/tasks';
  static const String getCanceledTasks = 'employee/canceled/tasks';
  static const String cancelEmployeeTask = 'cancel/employee/task';
  static const String cancelEmployeeTaskWithRepetition =
      'cancel/employee/task/with/repetition';
  static const String showEmployeeTask = 'show/employee/task';
  static const String editEmployeeTaskImages =
      'employee/edit/employee/task/images';

  // special tasks
  static const String getOngoingSpecialTasks = 'ongoing/special/tasks';
  static const String getNoDateSpecialTasks = 'no-date/special/tasks';
  static const String getCompletedSpecialTasks = 'completed/special/tasks';
  static const String changeSpecialTaskToCompleted =
      'change/special/task/to/completed';
  static const String showSpecialTask = 'show/special/task';
  static const String cancelSpecialTask = 'cancel/special/task';
  static const String cancelSpecialTaskWithRepetition =
      'cancel/special/task/with/repitition';
  static const String transferSpecialTask = 'transfer/special/task';
  static const String changeSubSpecialTaskToCompleted =
      'change/sub/special/task/to/completed';

  // Boxes
  static const String addBox = 'add/box';
  static const String getShownBoxes = 'get/shown/boxes';
  static const String getHiddenBoxes = 'get/hidden/boxes';
  static const String getBoxLogs = 'all/box/logs';
  static const String transferBoxBalance = 'transfer/box/balance';
  static const String showBox = 'show/box';
  static const String addBoxBalance = 'add/box/balance';
  static const String editBox = 'edit/box';
  static const String boxLogsReport = 'box/logs/report';
  static const String deleteBox = 'delete/box';

  // check section
  static const String notCashedIncomingChecks =
      'general/checks/data/first/page';
  static const String addOutgoingCheck = 'add/outgoing/check';
  static const String addIncomingCheck = 'add/incoming/check';

  static const String editOutgoingCheck = 'edit/outgoing/check';
  static const String editIncomingCheck = 'edit/incoming/check';

  static const String notCashedOutgoingChecks = 'not-cashed/outgoing/checks';
  static const String inComingChecks = 'not-cashed/incoming/checks';

  static const String cashedOutgoingChecks = 'cashed/to/person/outgoing/checks';
  static const String cashedIncomingChecks = 'cashed/to/person/incoming/checks';

  static const String archivedOutgoingChecks = 'archived/outgoing/checks';
  static const String archivedIncomingChecks = 'archived/incoming/checks';

  static const String cancelOutgoingCheck = 'cancel/an/outgoing/check';
  static const String cancelIncomingCheck = 'cancel/an/incoming/check';

  static const String cashOutgoingCheckToPerson =
      'cash/an/outgoing/check/to/person';
  static const String cashIncomingCheckToPerson =
      'cash/incoming/check/to/person';

  static const String cashOutgoingCheck = 'cash/an/outgoing/check';
  static const String cashIncomingCheck = 'cash/an/incoming/check';

  static const String returnOutgoingCheck = 'return/an/outgoing/check';
  static const String returnIncomingCheck = 'return/an/incoming/check';

  static const String all_customers = 'all/customers';
  static const String all_sellers = 'all/sellers';

  static const String generalIncomingChecks = 'general/incoming/checks/data';

  static const String chashIncomingCheckToBox = 'cash/incoming/check/to/box';

  // stock
  static const String getProductsList = 'get/products/list';
  static const String getUnarchivedCloseouts = 'get/unarchived/closeouts';
  static const String getAllCombinations = 'get/all/combinations';
  static const String getProductDetails = 'get/product/details';
  static const String archiveCloseout = 'archive/closeout';
  static const String addProductToCloseouts = 'add/product/to/closeouts';
  static const String getArchivedCloseouts = 'get/archived/closeouts';
  static const String getCategories = 'get/all/subcategories';
  static const String getProjects = 'get/all/projects';
  static const String searchProducts = 'search/products/by/name';
  static const String addCombination = 'add/combination';

  // sales
  static const String allProducts = 'all/products';
  static const String getInstantSaleInvoice = 'get/instant/sale/invoice';

  static const String createProfitSale = 'create/profit/sale';
  static const String allProfitSales = 'all/profit/sales';

  static const String createInstantSale = 'create/instant/sale';
  static const String allInstantSales = 'all/instant/sales';

  // general data list
  static const String createPerson = 'create/person';
  static const String editPerson = 'edit/person';
  static const String showPerson = 'show/person';

  static const String mainPageCustomers = 'main/page/customers';
  static const String mainPageSellers = 'main/page/sellers';
  static const String mainPageInComplete = 'main/page/incomplete/persons';

  // financial affairs
  // assets
  static const String addNewAsset = 'add/asset';
  static const String editAsset = 'edit/asset';
  static const String depreciateAssets = 'depreciate/all/assets';
  static const String assetsDetails = 'show/asset';
  static const String getAllAssets = 'get/all/assets';
  static const String getAssetsLogs = 'get/all/asset/logs';
  static const String getAllTreasuries = 'get/all/treasuries';
  static const String getFilePapers = 'file/papers';

  // expenses
  static const String getAllExpenses = 'get/all/expenses';
  static const String getAllDestructions = 'get/all/destructions';
  static const String addDestruction = 'store/destruction';
  static const String addExpense = 'store/expense';
  static const String editExpense = 'edit/expense';
  static const String showExpense = 'show/expense';

  // papers
  static const String getAllPapers = 'get/all/papers';
  static const String getAllPictures = 'get/all/pictures';
  static const String cancelPaper = 'cancel/paper';
  static const String addPicture = 'store/picture';
  static const String addPaper = 'store/paper';
  static const String storeTreasury = 'store/treasury';
  static const String storeFileBox = 'store/file-box';
  static const String storeFile = 'store/file';
  static const String getAllFiles = 'get/all/files';
  static const String deleteFile = 'delete/file';
  static const String deleteFileBox = 'cancel/file-box';
  static const String deleteTreasury = 'cancel/treasury';

  // projects
  static const String ongoingProjects = 'ongoing/project';
  static const String completedProjects = 'completed/project';
  static const String createProject = 'create/project';
  static const String editProject = 'edit/project';
  static const String showProject = 'show/project';
  static const String addProductToProject = 'add/product/to/project';
  static const String completeProject = 'complete/a/project';
  static const String projectSales = 'project/sales';
  static const String getProjectExpenses = 'get/project/expenses';
  static const String addProjectExpense = 'add/project/expense';

  // report information
  static const String getAllReportInformation = 'get/all/report/information';
  static const String getReportByType = 'get/reprot/by/type';

  // payment
  static const String addTransaction = 'add/transaction';

  // maintenance
  static const String addMaintenance = 'add/maintenance';
  static const String changeMaintenanceStatus = 'change/maintenance/status';
  static const String getNewMaintenances = 'get/new/maintenances';
  static const String getOngoingMaintenances = 'get/ongoing/maintenances';
  static const String getReadyMaintenances = 'get/ready/maintenances';
  static const String getDeliveredMaintenances = 'get/delivered/maintenances';
  static const String showMaintenance = 'show/maintenance';

  // goals
  static const String getAllGoals = 'get/all/goals';
  static const String addGoal = 'add/goal';
  static const String editGoal = 'edit/goal';
  static const String showGoal = 'show/goal';
  static const String transferGoal = 'transfer/goal';
  static const String cancelGoal = 'cancel/goal';

  // followups
  static const String addFollowup = 'add/followup';
  static const String updateFollowup = 'update/followup';
  static const String showFollowup = 'show/followup';
  static const String storeCustomer = 'followup/store/customer';
  static const String cancelFollowup = 'cancel/followup';
  static const String getInitialFollowups = 'get/initial/followups';
  static const String getInformPersonFollowups = 'get/inform/person/followups';
  static const String getFinishAndAgreementFollowups =
      'get/finish/and/agreement/followups';
  static const String getArchivedFollowups = 'get/archived/followups';

  // bills
  static const String addBill = 'add/bill';
  static const String addBillQuantity = 'add/quantity/bill';
  static const String addReturnPurchase = 'add/return/purchase';
  static const String getBillDetails = 'get/bill/details';
  static const String billReport = 'bill/report';
  static const String unfinishedBills = 'unfinished/bills';
  static const String archivedBills = 'archived/bills';
  static const String finishedBills = 'finished/bills';
  static const String unmatchedBills = 'unmatched/bills';
  static const String securitiesBills = 'securities/bills';
  static const String getPendingReturnPurchases =
      'get/pending/return/purchases';
  static const String getDeliveredReturnPurchases =
      'get/delivered/return/purchases';
  static const String cancelBill = 'cancel/bill';
  static const String changeProductStatus = 'change/product/status';
  static const String purchaseNewPrice = 'purchase/new/price';
  static const String deliverOneProduct = 'deliver/one/product';
  static const String purchaseExtraProducts = 'purchase/extra/products';
  static const String changeReturnPurchaseToDelivered =
      'change/return/purchase/to/delivered';

  // product developments
  static const String getAllProductDevelopments =
      'get/all/product/developments';
  static const String createProductDevelopment = 'create/product/development';
  static const String updateProductDevelopment =
      'update/product/development/step';
}

class ApiKey {
  static const String ar = 'ar';
  static const String en = 'en';
  static const String status = 'status';
  static const String data = 'data';
  static const String id = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String email_verified_at = 'email_verified_at';
  static const String phone = 'phone';
  static const String sub_phone = 'sub_phone';
  static const String city = 'city';
  static const String address = 'address';
  static const String created_at = 'created_at';
  static const String updated_at = 'updated_at';
  static const String type = 'type';
  static const String debts = 'debts';
  static const String total_debts_we_owe = 'total_debts_we_owe';
  static const String total_debts_owed_to_us = 'total_debts_owed_to_us';
  static const String customer_id = 'customer_id';
  static const String customer_name = 'customer_name';
  static const String customer_is_canceled = 'customer_is_canceled';
  static const String due_date = 'due_date';
  static const String total = 'total';
  static const String receipt_image = 'receipt_image';
  static const String notes = 'notes';
  static const String recipet_images_path = 'recipet_images_path';
  static const String debt_type = 'debt_type';
  static const String debt_created_at = 'debt_created_at';
  static const String customer_balance = 'customer_balance';
  static const String is_canceled_customer = 'is_canceled_customer';
  static const String customer_debts = 'customer_debts';
  static const String items = 'items';
  static const String employee_name = 'employee_name';
  static const String hour_work_price = 'hour_work_price';
  static const String points = 'points';
  static const String employee_img = 'employee_img';
  static const String user_name = 'user_name';
  static const String start_work_time = 'start_work_time';
  static const String end_work_time = 'end_work_time';
  static const String number_of_work_hours = 'number_of_work_hours';
  static const String working_times = 'working_times';
  static const String salary = 'salary';
  static const String financial_dues = 'financial_dues';
  static const String employee_id = 'employee_id';
  static const String total_work_hours = 'total_work_hours';
  static const String points_revenue = 'points_revenue';
  static const String financial_details = 'financial_details';
  static const String employee_details = 'employee_details';
  static const String overtime_work_price = 'overtime_work_price';
  static const String document_img = 'document_img';
  static const String permissions = 'permissions';
  static const String permission_id = 'permission_id';
  static const String permission_name = 'permission_name';
  static const String permission_name_en = 'permission_name_en';
  static const String qr_image_url = 'qr_image_url';
  static const String code_text = 'code_text';
  static const String employee_permissions = 'employee_permissions';
  static const String employee = 'employee';
  static const String fcm_token = 'fcm_token';
  static const String task_name = 'task_name';
  static const String start_time = 'start_time';
  static const String end_time = 'end_time';
  static const String is_canceled = 'is_canceled';
  static const String admin_img = 'admin_img';
  static const String audio = 'audio';
  static const String task_id = 'task_id';
  static const String description = 'description';
  static const String not_shown_for_employee = 'not_shown_for_employee';
  static const String is_forced_to_upload_img = 'is_forced_to_upload_img';
  static const String task_recurrence = 'task_recurrence';
  static const String task_recurrence_time = 'task_recurrence_time';
  static const String sub_tasks = 'sub_tasks';
  static const String sub_id = 'sub_id';
  static const String sub_name = 'sub_name';
  static const String sub_description = 'sub_description';
  static const String sub_status = 'sub_status';
  static const String sub_admin_img = 'sub_admin_img';
  static const String subtask_admin_img_path = 'subtask_admin_img_path';
  static const String employee_images_path = 'employee_images_path';
  static const String employees = 'employees';
  static const String start_date = 'start_date';
  static const String end_date = 'end_date';
  static const String ongoing_tasks = 'ongoing_tasks';
  static const String completed_tasks = 'completed_tasks';
  static const String canceled_tasks = 'canceled_tasks';
  static const String no_date_tasks = 'no_date_tasks';

  static const String stores = 'stores';
  static const String sellers = 'sellers';
  static const String package_id = 'package_id';
  static const String seller_type_id = 'seller_type_id';
  static const String seller_status = 'seller_status';
  static const String last_session = 'last_session';
  static const String subscription_details = 'subscription_details';
  static const String push_notifications_enabled = 'push_notifications_enabled';
  static const String is_seller = 'is_seller';
  static const String fullname = 'fullname';
  static const String seller_type_ar_description = 'seller_type_ar_description';
  static const String seller_type_en_description = 'seller_type_en_description';
  static const String products = 'products';
  static const String excluded_products = 'excluded_products';
  static const String price_before_discount = 'price_before_discount';
  static const String price_after_discount = 'price_after_discount';
  static const String discount_amount = 'discount_amount';
  static const String branches = 'branches';
  static const String notifications = 'notifications';
  static const String is_viewed = 'is_viewed';
  static const String viewed_at = 'viewed_at';
  static const String previous_state = 'previous_state';
  static const String current_state = 'current_state';
  static const String favorite_offers = 'favorite offers';
  static const String favorite_stores = 'favorite stores';
  static const String offer_id = 'offer_id';
  static const String price = 'price';
  static const String is_excluded_from_discount = 'is_excluded_from_discount';
  static const String discount = 'discount';
  static const String pending_requests = 'pending_requests';
  static const String paid_requests = 'paid_requests';
  static const String amount = 'amount';
  static const String subscription_id = 'subscription_id';
  static const String quantity = 'quantity';
  static const String product_id = 'product_id';
  static const String product = 'product';
  static const String offer = 'offer';
  static const String total_before_discount = 'total_before_discount';
  static const String total_after_discount = 'total_after_discount';
  static const String total_discount_amount = 'total_discount_amount';
  static const String amount_after_discount = 'amount_after_discount';
  static const String period_in_months = 'period_in_months';
  static const String expiry_date = 'expiry_date';
  static const String expires_at = 'expires_at';
  static const String package = 'package';
  static const String user = 'user';
  static const String body = 'body';
  static const String parent_id = 'parent_id';
  static const String responses = 'responses';
  static const String pivot = 'pivot';
  static const String name_ar = 'name_ar';
  static const String city_id = 'city_id';
  static const String requests = 'requests';
  static const String image = 'image';
}
