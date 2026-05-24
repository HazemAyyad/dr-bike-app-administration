import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return Scaffold(
      body: nav.animatedSwitch(),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
