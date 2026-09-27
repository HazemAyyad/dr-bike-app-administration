import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/helpers/custom_floating_action_button.dart';
import '../../../core/services/initial_bindings.dart';
import '../../admin/admin_dashbord/presentation/widgets/dashboard_design_tokens.dart';
import '../controllers/bottom_nav_bar_controller.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class BottomNavBarScreen extends StatelessWidget {
  const BottomNavBarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BottomNavBarController>()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final nav = Get.find<BottomNavBarController>();
    return Obx(() {
      final role =
          sessionUserType.value.isNotEmpty ? sessionUserType.value : userType;
      final showAdminFab = role == 'admin' && nav.currentIndex.value == 0;
      final dashboardController =
          showAdminFab ? nav.ensureAdminDashboardController() : null;
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: nav.animatedSwitch()),
            if (dashboardController != null)
              Positioned.fill(
                child: CustomFloatingActionButton(
                  isAddMenuOpen: dashboardController.isAddMenuOpen,
                  onTap: dashboardController.toggleAddMenu,
                  opacityAnimation: dashboardController.sizeAnimation,
                  sizeAnimation: dashboardController.opacityAnimation,
                  addList: dashboardController.visibleAdminAddList,
                  useGrid: true,
                  backgroundColor: DashboardDesignTokens.primary,
                  compact: true,
                  centered: true,
                  overlayOnly: true,
                ),
              ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(),
        floatingActionButton: dashboardController == null
            ? null
            : CustomFloatingActionButton(
                isAddMenuOpen: dashboardController.isAddMenuOpen,
                onTap: dashboardController.toggleAddMenu,
                opacityAnimation: dashboardController.sizeAnimation,
                sizeAnimation: dashboardController.opacityAnimation,
                addList: dashboardController.visibleAdminAddList,
                useGrid: true,
                backgroundColor: DashboardDesignTokens.primary,
                compact: true,
                centered: true,
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }
}
