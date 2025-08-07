import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../--/presentation/project_management/widgets/project_details/sup_text_and_dis.dart';
import '../../controllers/target_section_controller.dart';

class TargetDetailsScreen extends GetView<TargetSectionController> {
  const TargetDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var target = Get.arguments;
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'targetDetails',
        action: false,
        actions: [
          GestureDetector(
            onTap: () {
              // Handle cancel order action
              print('Cancel ${target['targetName']}');
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              height: 32.h,
              width: 104.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 1.w,
                ),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Center(
                child: Text(
                  'cancelTarget'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          // target details view
          SizedBox(height: 10.w),
          supTextAndDis(context, 'targetName', target['targetName']),
          SizedBox(height: 10.w),
          supTextAndDis(context, 'targetType', target['targetType']),
          SizedBox(height: 10.w),
          supTextAndDis(context, 'mainValue', target['mainValue']),
          SizedBox(height: 10.w),
          supTextAndDis(context, 'targetValue', target['targetValue']),
          SizedBox(height: 10.w),
          supTextAndDis(context, 'notes', target['notes']),
          SizedBox(height: 10.w),
          supTextAndDis(context, 'followUp', target['followUp']),
          SizedBox(height: 10.w),
          Row(
            children: [
              SizedBox(width: 30.w),
              Flexible(
                child: supTextAndDis(
                  context,
                  'targetName',
                  target['targetName'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
