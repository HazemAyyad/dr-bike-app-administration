import 'package:doctorbike/features/admin/employee_section/domain/usecases/qr_scan_usecase.dart';
import 'package:doctorbike/features/admin/employee_section/presentation/controllers/qrcode_controller.dart';
import 'package:doctorbike/features/common_feature/presentation/user_profile/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../admin/--/presentation/dashbord/controllers/dashboard_controller.dart';
import '../../admin/--/presentation/dashbord/views/dashboard_screen.dart';
import '../../admin/employee_section/data/repositorie_imp/employee_section_implement.dart';
import '../../admin/employee_section/domain/usecases/get_all_employee.dart';
import '../../admin/employee_section/presentation/controllers/employee_service.dart';
import '../../admin/employee_section/presentation/views/qr_code_screen.dart';
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
        duration: Duration(milliseconds: 300),
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
        if (!Get.isRegistered<DashboardController>()) {
          Get.put(
            DashboardController(
              getAllEmployeeUsecase: GetAllEmployeeUsecase(
                employeeRepository: Get.find<EmployeeImplement>(),
              ),
              employeeService: Get.find<EmployeeService>(),
            ),
          );
        }
        return DashboardScreen(key: ValueKey(0));
      case 1:
        if (!Get.isRegistered<QrCodeController>()) {
          Get.put(
            QrCodeController(
              qrScanUsecase: QrScanUsecase(
                employeeRepository: Get.find<EmployeeImplement>(),
              ),
            ),
          );
        }
        return FullScreenQRScanner(key: ValueKey(1));
      case 2:
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
        return ProfileScreen(key: ValueKey(2));
      default:
        return HomePageScreen(key: ValueKey(1));
    }
  }
}
