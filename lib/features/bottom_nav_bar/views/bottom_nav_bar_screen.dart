import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/bottom_nav_bar_controller.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class BottomNavBarScreen extends GetView<BottomNavBarController> {
  const BottomNavBarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true,
      body: controller.animatedSwitch(),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
