import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../widgets/create_qrcode.dart';
import '../widgets/employee_sections_list/employee_section.dart';

class EmployeeSectionScreen extends GetView<EmployeeSectionController> {
  const EmployeeSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeSection',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        employeeNameController: controller.employeeNameController,
        actions: [
          IconButton(
            icon: Icon(
              Icons.redeem,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 25.sp,
            ),
            onPressed: () => Get.toNamed(AppRoutes.POINTSTABLE),
          ),
          IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 27.sp,
            ),
            onPressed: () => Get.toNamed(AppRoutes.ACTIVITYLOGSCREEN),
          ),
          IconButton(
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 22.sp,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
            onPressed: () {
              showCustomDialog(
                context,
                fromDateController: controller.fromDateController,
                toDateController: controller.toDateController,
                employeeNameController: controller.employeeNameController,
                label: 'employeeName',
                onPressed: () {},
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          EmployeeSection(controller: controller),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.addList,
        customWidget: BuildAddMenuItem(
          title: 'barcode',
          iconAsset: AssetsManger.qrcode,
          route: '',
          onTap: () {
            controller.toggleAddMenu();
            Get.dialog(CreateQrcode());
          },
        ),
      ),
    );
  }
}
