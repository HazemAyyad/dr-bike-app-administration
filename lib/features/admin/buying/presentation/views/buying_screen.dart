import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/buying_controller.dart';

class BuyingScreen extends GetView<BuyingController> {
  const BuyingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'purchasesandReturns',
        action: false,
      ),
      body: Container(
        child: Center(
          child: Text('purchasesandReturns'.tr),
        ),
      ),
    );
  }
}
