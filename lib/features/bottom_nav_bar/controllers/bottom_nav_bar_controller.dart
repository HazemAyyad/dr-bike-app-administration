import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/features/employee/employee_dashbord/presentation/views/employee_dashbord_screen.dart';
import 'package:doctorbike/features/employee/scan_qrcode/domain/usecases/qr_scan_usecase.dart';
import 'package:doctorbike/features/employee/scan_qrcode/presentation/controllers/qrcode_controller.dart';
import 'package:doctorbike/features/common_feature/presentation/user_profile/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../admin/admin_dashbord/data/repositories/admin_dashboard_implement.dart';
import '../../admin/admin_dashbord/domain/usecases/get_admin_logs_usecase.dart';
import '../../admin/admin_dashbord/presentation/controllers/admin_dashboard_controller.dart';
import '../../admin/admin_dashbord/presentation/views/admin_dashboard_screen.dart';
import '../../admin/employee_section/data/repositorie_imp/employee_implement.dart';
import '../../admin/employee_section/domain/usecases/cancel_log_usecase.dart';
import '../../admin/employee_section/domain/usecases/get_all_employee.dart';
import '../../employee/employee_dashbord/data/repositories/employee_dashbord_implement.dart';
import '../../employee/employee_dashbord/domain/usecases/change_task_completed_uasecase.dart';
import '../../employee/employee_dashbord/domain/usecases/get_employee_data_usecase.dart';
import '../../employee/employee_dashbord/domain/usecases/request_over_time_loan_usecase.dart';
import '../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../employee/scan_qrcode/data/repositories/scan_qrcode_implement.dart';
import '../../employee/scan_qrcode/presentation/views/qr_code_screen.dart';
import '../../common_feature/presentation/user_profile/controllers/profile_controller.dart';
import '../../home/views/home_page_screen.dart';

class BottomNavBarController extends GetxController {
  // متغير لتتبع الصفحة الحالية
  var currentIndex = 0.obs;

  // دالة لتغيير الصفحة الحالية
  void changePage(int index) {
    currentIndex.value = index;
  }

  Widget animatedSwitch() {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _getPage(currentIndex.value),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        if (userType == 'admin') {
          if (!Get.isRegistered<AdminDashboardController>()) {
            Get.put(
              AdminDashboardController(
                getAllEmployeeUsecase: GetAllEmployeeUsecase(
                  employeeRepository: Get.find<EmployeeImplement>(),
                ),
                getAdminLogsUsecase: GetAdminLogsUsecase(
                  adminDashboardRepository: Get.find<AdminDashboardImplement>(),
                ),
                cancelLogUsecase: CancelLogUsecase(
                  employeeRepository: Get.find<EmployeeImplement>(),
                ),
              ),
            );
            return const AdminDashboardScreen();
          }
          return const AdminDashboardScreen();
        } else {
          if (!Get.isRegistered<EmployeeDashbordController>()) {
            Get.put(
              EmployeeDashbordController(
                requestOverTimeLoanUsecase: RequestOverTimeLoanUsecase(
                  employeeDashbordRepository:
                      Get.find<EmployeeDashbordImplement>(),
                ),
                getEmployeeDataUsecase: GetEmployeeDataUsecase(
                  employeeDashbordRepository:
                      Get.find<EmployeeDashbordImplement>(),
                ),
                changeTaskCompletedUasecase: ChangeTaskCompletedUasecase(
                  employeeDashbordRepository:
                      Get.find<EmployeeDashbordImplement>(),
                ),
              ),
            );
          }
          return const EmployeeDashbordScreen();
        }
      case 1:
        if (!Get.isRegistered<QrCodeController>()) {
          Get.put(
            QrCodeController(
              qrScanUsecase: QrScanUsecase(
                scanQrCodeRepository: Get.find<ScanQrCodeImplement>(),
              ),
            ),
          );
        }
        return const FullScreenQRScanner(key: ValueKey(1));
      case 2:
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
        return const ProfileScreen(key: ValueKey(2));
      default:
        return const HomePageScreen(key: ValueKey(1));
    }
  }
}
